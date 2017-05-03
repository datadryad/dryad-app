require 'stash/repo/submission_job'
require 'fileutils'

module Stash
  module Repo
    # Abstraction for a repository
    class Repository
      attr_reader :url_helpers

      # Initializes this repository
      # @param url_helpers [Module] Rails URL helpers
      def initialize(url_helpers:)
        @url_helpers = url_helpers
      end

      # Creates a {SubmissionJob} for the specified resource
      # @param resource_id [Integer] the database ID of the resource
      # @return [SubmissionJob] a job that will submit that resource
      def create_submission_job(resource_id:) # rubocop:disable Lint/UnusedMethodArgument
        raise NoMethodError, "#{self.class} should override #create_submission_job to return one or more submission tasks"
      end

      # Determines the download URI for the specified resource. Called after the record is harvested
      # for discovery.
      # @param resource [StashEngine::Resource] the resource
      # @param record_identifier [String] the harvested record identifier (repository- or protocol-dependent)
      def download_uri_for(resource:, record_identifier:) # rubocop:disable Lint/UnusedMethodArgument
        raise NoMethodError, "#{self.class} should override #download_uri_for to determine the download URI"
      end

      # Determines the update URI for the specified resource. Called after the record is harvested
      # for discovery.
      # @param resource [StashEngine::Resource] the resource
      # @param record_identifier [String] the harvested record identifier (repository- or protocol-dependent)
      def update_uri_for(resource:, record_identifier:) # rubocop:disable Lint/UnusedMethodArgument
        raise NoMethodError, "#{self.class} should override #update_uri_for to determine the update URI"
      end

      # Returns a logger
      # @return [Logger] a logger
      def log
        Rails.logger
      end

      # Calls {#create_submission_job} to create a submission job,
      # and executes it in the background using {Concurrent#global_io_executor},
      # "a global thread pool optimized for long, blocking (IO) tasks",
      # updates the resource state and sends notification email based
      # on the result.
      # @param resource_id [Integer] the ID of the resource
      def submit(resource_id:)
        StashEngine::Resource.find(resource_id).current_state = 'processing'
        submission_job = create_submission_job(resource_id: resource_id)
        promise = submission_job.submit_async
        promise.on_success do |result|
          result.success? ? handle_success(result) : handle_failure(result)
        end
        promise.rescue do |reason|
          handle_failure(SubmissionResult.new(resource_id: resource_id, request_desc: submission_job.description, error: reason))
        end
      end

      def harvested(identifier:, record_identifier:)
        resource = identifier.processing_resource
        return unless resource # harvester could be re-harvesting stuff we already have

        # TODO: do we need to do any validation here? If so & validation fails, we should return a 422 or 409 (see RFC 5789 sec. 2.2)
        download_uri = download_uri_for(resource: resource, record_identifier: record_identifier)
        update_uri = update_uri_for(resource: resource, record_identifier: record_identifier)

        resource.download_uri = download_uri
        resource.update_uri = update_uri
        resource.current_state = 'submitted'
        resource.save
      end

      private

      def handle_success(result)
        result.log_to(log)
        resource = StashEngine::Resource.find(result.resource_id)
        resource.current_state = 'submitted'
        update_submission_log(result)
        StashEngine::UserMailer.submission_succeeded(resource).deliver_now
        cleanup_files(resource)
      rescue => e
        # errors here don't constitute a submission failure, so we don't change the resource state
        log_error(e)
      end

      def handle_failure(result)
        result.log_to(log)
        update_submission_log(result)
        resource = StashEngine::Resource.find(result.resource_id)
        StashEngine::UserMailer.error_report(resource, result.error).deliver_now
        StashEngine::UserMailer.submission_failed(resource, result.error).deliver_now
      rescue => e
        log_error(e)
      ensure
        resource.current_state = 'error' if resource
      end

      def log_error(error)
        log.error(to_msg(error))
      end

      def cleanup_files(resource)
        resource.file_uploads.map(&:temp_file_path).each { |file| remove_if_exists(file) }
        res_upload_dir = StashEngine::Resource.upload_dir_for(resource.id)
        remove_if_exists(res_upload_dir)
      rescue => e
        msg = "An unexpected error occurred when cleaning up files for resource #{resource.id}: "
        msg << to_msg(e)
        log.warn(msg)
      end

      def remove_if_exists(file)
        FileUtils.remove_entry_secure(file) if File.exist?(file)
      end

      def to_msg(error)
        msg = error.to_s
        if (backtrace = (error.respond_to?(:backtrace) && error.backtrace))
          backtrace.each do |line|
            msg << "\n"
            msg << line
          end
        end
        msg
      end

      def update_submission_log(result)
        StashEngine::SubmissionLog.create(
          resource_id: result.resource_id,
          archive_submission_request: result.request_desc,
          archive_response: (result.message || result.error.to_s)
        )
      end
    end
  end
end
