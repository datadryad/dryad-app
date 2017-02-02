require 'stash/repo/submission_job'
require 'fileutils'

module Stash
  module Repo
    class Repository

      attr_reader :url_helpers

      def initialize(url_helpers:)
        @url_helpers = url_helpers
      end

      def create_submission_job(resource_id:) # rubocop:disable Lint/UnusedMethodArgument
        raise NoMethodError, "#{self.class} should override #create_submission_job to return one or more submission tasks"
      end

      def log
        Rails.logger
      end

      def submit(resource_id:)
        StashEngine::Resource.find(resource_id).current_state = 'processing'
        create_submission_job = create_submission_job(resource_id: resource_id)
        promise = create_submission_job.submit_async
        promise.on_success { |result| result.success? ? handle_success(result) : handle_failure(result) }
        promise.rescue { |reason| handle_failure(SubmissionResult.new(resource_id: resource_id, error: reason)) }
      end

      private

      def handle_success(result)
        result.log_to(log)
        resource = StashEngine::Resource.find(result.resource_id)
        resource.current_state = 'published'
        StashEngine::UserMailer.submission_succeeded(resource).deliver_now
        cleanup_files(resource)
      rescue => e
        # errors here don't constitute a submission failure, so we don't change the resource state
        log_error(e)
      end

      def handle_failure(result)
        result.log_to(log)
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

    end
  end
end
