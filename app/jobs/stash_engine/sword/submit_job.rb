require 'stash/sword'

require 'concurrent/async'

module StashEngine
  module Sword
    # Background job for asynchronous SWORD submission
    class SubmitJob
      include Concurrent::Async

      # Creates a {SubmitJob} and submits it on a background thread, logging the result.
      #
      # @param sword_package [Package] the package to submit
      # @return [Concurrent::Ivar] a future containing the submitted resource, or an error
      def self.submit_async(sword_package)
        title = sword_package.title
        resource_id = sword_package.resource_id
        doi = sword_package.doi
        Rails.logger.debug("Creating SubmitJob for resource #{resource_id}: '#{title}' (#{doi})")

        future = SubmitJob.new(
          title: title,
          doi: doi,
          zipfile: sword_package.zipfile,
          resource_id: resource_id,
          sword_params: sword_package.sword_params,
          request_host: sword_package.request_host,
          request_port: sword_package.request_port
        ).async.submit

        future.add_observer(FileCleanupObserver.new(resource_id: resource_id))
        future.add_observer(ResultLoggingObserver.new(title: title, doi: doi))
        future
      end

      # Creates a new {SubmitJob}.
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
        # TODO: collapse this into single method on resource
        resource.update_uri ? update(resource) : create(resource)
        resource.current_state = 'published'
        resource.version_zipfile = zipfile
        update_submission_log(resource_id: resource_id, request_msg: request_msg, response_msg: 'Success')
        resource
      end

      def report_error(e, resource, request_msg)
        log.error("#{e}\n#{e.backtrace.join("\n")}")

        update_submission_log(resource_id: resource_id, request_msg: request_msg, response_msg: "Failed: #{e}")
        resource = Resource.find(resource_id) unless resource
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
        # TODO: collapse this into single method on resource
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

    # Logs the result of the SubmitJob, whether success or failure
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
      # {SubmitJob} async background task
      # @param time [Time] the time the job completed
      # @param value [Resource, nil] the resource updated, or nil in the event of a failure
      # @param reason [Error, nil] any error, or nil in the event of success
      def update(time, value, reason)
        reason ? log_failure(time, reason) : log_success(time, value)
      end

      def log_failure(time, reason)
        log.warn("SubmitJob for '#{title}' (#{doi}) failed at #{time}: #{reason}")
      end

      def log_success(time, resource)
        download_uri = resource ? resource.download_uri : 'nil'
        update_uri = resource ? resource.update_uri : 'nil'
        log.info("SubmitJob for '#{title}' (#{doi}) completed at #{time}: download_uri = #{download_uri}, update_uri = #{update_uri}")
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
      # {SubmitJob} async background task.  if reason is not set then successful
      def update(time, value, reason)
        unless reason
          res = Resource.where(id: @resource_id).first
          if (uploads = res.try(:file_uploads))
            log.info("#{self.class} removing uploaded files for resource_id: #{@resource_id}")
            uploads.each do |upload|
              File.delete(upload.temp_file_path) if File.exist?(upload.temp_file_path)
            end
            #delete directory
            upload_dir = StashEngine::Resource.upload_dir_for(@resource_id)
            if File.exist?(upload_dir)
              Dir.rmdir(upload_dir)
            end
          end
          #delete any zipfiles and temp files
          files = Dir[File.join(StashEngine::Resource.uploads_dir, "#{@resource_id.to_s}_*")]
          files.each do |file|
            File.delete(file) if File.exist?(file)
          end
        end
      end
    end
  end
end
