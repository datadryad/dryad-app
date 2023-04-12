require 'fileutils'
require 'concurrent'
module Stash
  module Repo
    # Abstraction for a repository
    class Repository
      attr_reader :url_helpers, :executor

      # Initializes this repository
      # @param url_helpers [Module] Rails URL helpers
      # Concurrent::FixedThreadPool.new(2, idletime: 600)
      def initialize(url_helpers:, executor: nil, threads: 1)
        @executor = executor
        @url_helpers = url_helpers
        return unless @executor.nil?

        @executor = Concurrent::ThreadPoolExecutor.new(
          min_threads: 0,
          max_threads: threads,
          max_queue: 0,
          fallback_policy: :abort
        )
      end

      # the cached hostname so we can save the host, cached because we don't want to do this everytime
      # Rubocop is giving dumb advice below since I don't want to have to create an instance to access this and I want to cache it.
      # It is also always running on the same server so will not change where the code is running.
      # rubocop:disable Style/ClassVars
      def self.hostname
        @@hostname ||= `hostname`.strip
      end
      # rubocop:enable Style/ClassVars

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
      def download_uri_for(record_identifier:) # rubocop:disable Lint/UnusedMethodArgument
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
      def logger
        Rails.logger
      end

      # Calls {#create_submission_job} to create a submission job,
      # and executes it in the background using {Concurrent#global_io_executor},
      # "a global thread pool optimized for long, blocking (IO) tasks",
      # updates the resource state and sends notification email based
      # on the result.
      # @param resource_id [Integer] the ID of the resource
      def submit(resource_id:)
        res = StashEngine::Resource.find(resource_id)
        res.current_state = 'processing'
        if self.class.hold_submissions?
          self.class.update_repo_queue_state(resource_id: resource_id, state: 'rejected_shutting_down')
          return
        end
        submission_job = create_submission_job(resource_id: resource_id)
        self.class.update_repo_queue_state(resource_id: resource_id, state: 'enqueued')
        promise = submission_job.submit_async(executor: @executor)
        promise.on_success do |result|
          # deferred submissions are considered a success for our purposes (ie, qualified/probable success) and have
          # deferred? set on the submission_result object to indicate their odd status
          result.success? ? handle_success(result) : handle_failure(result)
        end
        promise.rescue do |reason|
          handle_failure(SubmissionResult.new(resource_id: resource_id, request_desc: submission_job.description, error: reason))
        end
      end

      def harvested(identifier:, record_identifier:)
        resource = identifier.processing_resource
        return unless resource # harvester could be re-harvesting stuff we already have

        resource.download_uri = get_download_uri(resource, record_identifier)
        resource.update_uri = get_update_uri(resource, record_identifier)
        resource.current_state = 'submitted'
        resource.save
        # Keep files until they've been successfully confirmed in the OAI-PMH feed, don't aggressively clean up until then
        # cleanup_files(resource)
      end

      # this will be called after Merritt confirms successful ingest by OAI-PMH feed to prevent deleting files
      # before we know they're really good in Merritt for a good safety net.
      def cleanup_files(resource)
        remove_public_dir(resource) # where the local manifest file is stored
        remove_s3_data_files(resource)
      rescue StandardError => e
        msg = "An unexpected error occurred when cleaning up files for resource #{resource.id}: "
        msg << e.full_message
        logger.warn(msg)
      end

      def self.update_repo_queue_state(resource_id:, state:)
        StashEngine::RepoQueueState.create(resource_id: resource_id, hostname: hostname, state: state)
      end

      # detect if we should be holding submissions because a hold-submissions.txt file exists one directory above Rails.root
      def self.hold_submissions?
        File.exist?(File.expand_path(File.join(Rails.root, '..', 'hold-submissions.txt')))
      end

      private

      def get_download_uri(resource, record_identifier)
        download_uri_for(record_identifier: record_identifier)
      rescue StandardError => e
        raise ArgumentError, "Unable to determine download URI for resource #{resource.id} from record identifier #{record_identifier}: #{e}"
      end

      def get_update_uri(resource, record_identifier)
        update_uri_for(resource: resource, record_identifier: record_identifier)
      rescue StandardError => e
        raise ArgumentError, "Unable to determine update URI for resource #{resource.id} from record identifier #{record_identifier}: #{e}"
      end

      def handle_success(result)
        result.log_to(logger)
        update_submission_log(result)

        # don't set new queue state on deferred submission results until the OAI-PMH feed does it for us, it's still
        # in progress until that happens.
        self.class.update_repo_queue_state(resource_id: result.resource_id, state: 'provisional_complete') unless result.deferred?
      rescue StandardError => e
        # errors here don't constitute a submission failure, so we don't change the resource state
        log_error(e)
      end

      # rubcop:disable Metrics/MethodLength
      def handle_failure(result)
        result.log_to(logger)
        update_submission_log(result)
        self.class.update_repo_queue_state(resource_id: result.resource_id, state: 'errored')
        resource = StashEngine::Resource.find(result.resource_id)
        StashEngine::UserMailer.error_report(resource, result.error).deliver_now
      rescue StandardError => e
        log_error(e)
      ensure
        resource.current_state = 'error' if resource.present?
      end
      # rubcop:enable Metrics/MethodLength

      def log_error(error)
        logger.error(error.full_message)
      end

      def remove_if_exists(file)
        return if file.blank?

        FileUtils.remove_entry_secure(file, true)
      end

      def remove_public_dir(resource)
        res_public_dir = Rails.public_path.join('system').join(resource.id.to_s)
        remove_if_exists(res_public_dir)
      end

      def remove_s3_data_files(resource)
        Stash::Aws::S3.delete_dir(s3_key: resource.s3_dir_name(type: 'manifest').to_s)
        Stash::Aws::S3.delete_dir(s3_key: resource.s3_dir_name(type: 'data').to_s)
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
