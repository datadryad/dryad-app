require 'stash/sword'

module StashEngine
  # a class for asynchronous sword submission
  class SwordJob
    include Concurrent::Async

    # Creates a {SwordJob} and submits it on a background thread, logging the result.
    #
    # @param title [String] The title of the dataset being submitted
    # @param doi [String] The DOI of the dataset being submitted
    # @param zipfile [String] The local path, on the server, of the zipfile to be submitted
    # @param resource_id [Integer] The ID of the resource being submitted
    # @param sword_params [Hash] Initialization parameters for `Stash::Sword::Client`.
    #   See the [stash-sword documentation](http://www.rubydoc.info/gems/stash-sword/Stash/Sword/Client#initialize-instance_method)
    #   for details.
    # @param request_host [String] The public hostname of the application UI. Used to generate links in the
    #   notification email.
    # @param request_port [Integer] The public-facing port of the application UI. Used to generate links in the
    #   notification email.
    def self.submit_async(title:, doi:, zipfile:, resource_id:, sword_params:, request_host:, request_port:) # rubocop:disable Metrics/ParameterLists, Metrics/LineLength
      result = SwordJob.new(
        title: title,
        doi: doi,
        zipfile: zipfile,
        resource_id: resource_id,
        sword_params: sword_params,
        request_host: request_host,
        request_port: request_port
      ).async.submit

      # it seems like only the first observer actually gets called
      result.add_observer(FileCleanupObserver.new(resource_id: resource_id))
      result.add_observer(ResultLoggingObserver.new(title: title, doi: doi))
    end

    # Creates a new {SwordJob}.
    #
    # @param title [String] The title of the dataset being submitted
    # @param doi [String] The DOI of the dataset being submitted
    # @param zipfile [String] The local path, on the server, of the zipfile to be submitted
    # @param resource_id [Integer] The ID of the resource being submitted
    # @param sword_params [Hash] Initialization parameters for `Stash::Sword::Client`. See the
    #   [stash-sword documentation](http://www.rubydoc.info/gems/stash-sword/Stash/Sword/Client#initialize-instance_method)
    #   for details.
    # @param request_host [String] The public hostname of the application UI. Used to generate links in the
    #   notification email.
    # @param request_port [Integer] The public-facing port of the application UI. Used to generate links in the
    #   notification email.
    def initialize(title:, doi:, zipfile:, resource_id:, sword_params:, request_host:, request_port:) # rubocop:disable Metrics/ParameterLists, Metrics/LineLength
      super()
      @title = title
      @doi = doi
      @zipfile = zipfile
      @resource_id = resource_id
      @sword_params = sword_params
      @request_host = request_host
      @request_port = request_port
    end

    # Submits this job
    def submit
      log.debug("#{self.class}.submit() at #{Time.now}: title: '#{title}', doi: #{doi}, zipfile: #{zipfile}, "\
                "resource_id: #{resource_id}, sword_params: #{sword_params}")
      request_msg = "Submitting #{zipfile} for '#{title}' (#{doi}) at #{Time.now}: "\
                    "#{(sword_params.map { |k, v| "#{k}: #{v}" }).join(', ')}"
      resource = nil
      begin
        resource = do_submit(request_msg)
      rescue => e
        report_error(e, resource, request_msg)
        raise
      end
    end

    private

    attr_reader :title
    attr_reader :doi
    attr_reader :zipfile
    attr_reader :resource_id
    attr_reader :sword_params
    attr_reader :request_host
    attr_reader :request_port

    def log
      Rails.logger
    end

    def client
      @client ||= Stash::Sword::Client.new(logger: log, **sword_params)
    end

    def do_submit(request_msg)
      resource = Resource.find(resource_id)
      resource.update_uri ? update(resource) : create(resource)
      resource.current_state = 'published'
      resource.update_version(zipfile)
      update_submission_log(resource_id: resource_id, request_msg: request_msg, response_msg: 'Success')
      resource
    end

    def report_error(e, resource, request_msg)
      log.error(e.to_s + (backtrace = e.backtrace) && "\n#{backtrace.join("\n")}")

      update_submission_log(resource_id: resource_id, request_msg: request_msg, response_msg: "Failed: #{e}")
      error_report(resource, e).deliver_now
      failure_report(resource, e).deliver_now

      resource.current_state = 'error' if resource

      # TODO: Enable this (and don't raise) once we have ExceptionNotifier configured
      # ExceptionNotifier.notify_exception(e, data: {title: title, doi: doi, zipfile: zipfile,
      # resource_id: resource_id, sword_params: sword_params})
    end

    def create(resource)
      log.debug("invoking create(doi: #{doi}, zipfile: #{zipfile}) for resource #{resource.id} (title: '#{title}')")
      receipt = client.create(doi: doi, zipfile: zipfile)
      log.debug("create(doi: #{doi}, zipfile: #{zipfile}) for resource #{resource.id} completed with em_iri "\
                "#{receipt.em_iri}, edit_iri #{receipt.edit_iri}")
      resource.download_uri = receipt.em_iri
      resource.update_uri = receipt.edit_iri
      resource.save # save download and update URLs for this resource
      log.debug("resource #{resource.id} saved")
      UserMailer.create_succeeded(resource, title, request_host, request_port).deliver_now
    end

    def update(resource)
      update_uri = resource.update_uri
      log.debug("invoking update(edit_iri: #{update_uri}, zipfile: #{zipfile}) for resource #{resource.id} "\
                "(title: '#{title}')")
      status = client.update(edit_iri: update_uri, zipfile: zipfile)
      log.debug("update(edit_iri: #{update_uri}, zipfile: #{zipfile}) for resource #{resource.id} completed "\
                "with status #{status}")
      UserMailer.update_succeeded(resource, title, request_host, request_port).deliver_now
    end

    def update_submission_log(resource_id:, request_msg:, response_msg:)
      SubmissionLog.create(resource_id: resource_id, archive_submission_request: request_msg,
                           archive_response: response_msg)
    end

    # Generates an error report (w/stack trace) to be emailed to Stash administrators
    #
    # @param resource [Resource, nil] The resource, or nil if the resource could not be found in the database
    #   at submission time
    # @param e [Exception] The error
    # @return [ActionMailer::MessageDelivery] a deliverable email message
    def error_report(resource, e)
      UserMailer.error_report(resource, title, e)
    end

    # Generates a failure report (w/link to 'My Datasets' page) to be emailed to the owner of the
    # dataset that could not be submitted
    #
    # @param resource [Resource, nil] The resource, or nil if the resource could not be found in the database
    #   at submission time
    # @param e [Exception] The error
    # @return [ActionMailer::MessageDelivery] a deliverable email message
    def failure_report(resource, e)
      if resource && resource.update_uri
        UserMailer.update_failed(resource, title, request_host, request_port, e)
      else
        UserMailer.create_failed(resource, title, request_host, request_port, e)
      end
    end
  end

  # Logs the result of the SwordJob, whether success or failure
  class ResultLoggingObserver
    def log
      Rails.logger
    end

    attr_reader :title
    attr_reader :doi

    # Creates a new {ResultLoggingObserver}
    # @param title [String] the title of the dataset being submitted
    # @param doi [String] the DOI of the dataset being submitted
    def initialize(title:, doi:)
      @doi = doi
      @title = title
    end

    # Called by the `Concurrent::Async` framework on completion of the
    # {SwordJob} async background task
    def update(time, value, reason)
      reason ? log_failure(time, reason) : log_success(time, value)
    end

    def log_failure(time, reason)
      log.warn("SwordJob for '#{title}' (#{doi}) failed at #{time}: #{reason}")
    end

    def log_success(time, value)
      msg = value ? value.archive_response : 'nil'
      log.info("SwordJob for '#{title}' (#{doi}) completed at #{time}: #{msg}")
    end
  end

  class FileCleanupObserver

    def log
      Rails.logger
    end

    attr_reader :resource_id

    def initialize(resource_id:)
      @resource_id = resource_id
      log.info('FileCleanup initialized')
    end

    # Called by the `Concurrent::Async` framework on completion of the
    # {SwordJob} async background task.  if reason is not set then successful
    def update(time, value, reason)
      unless reason
        res = Resource.where(id: @resource_id).first
        if uploads = res.try(:file_uploads)
          log.info("#{self.class} removing uploaded files for resource_id: #{@resource_id}")
          uploads.each do |upload|
            File.delete(upload.temp_file_path) if File.exist?(upload.temp_file_path)
          end
          #delete directory
          if File.exist?(File.join(Rails.root, 'uploads', @resource_id.to_s))
            Dir.rmdir(File.join(Rails.root, 'uploads', @resource_id.to_s))
          end
        end
        #delete any zipfiles and temp files
        files = Dir[File.join(Rails.root, 'uploads', "#{@resource_id.to_s}_*")]
        files.each do |file|
          File.delete(file) if File.exist?(file)
        end
      end
    end
  end
end
