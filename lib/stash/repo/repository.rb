require 'fileutils'
require 'concurrent'

module Stash
  module Repo
    class Repository
      attr_reader :executor

      ARK_PATTERN = %r{ark:/[a-z0-9]+/[a-z0-9]+}

      # Initializes this repository
      # Concurrent::FixedThreadPool.new(2, idletime: 600)
      def initialize(executor: nil, threads: 1)
        @executor = executor
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

      # # Creates a {SubmissionJob} for the specified resource
      # # @param resource_id [Integer] the database ID of the resource
      # # @return [SubmissionJob] a job that will submit that resource
      # def create_submission_job(resource_id:)
      #   Submission::SubmissionJob.new(resource_id: resource_id)
      #   # SubmissionJob.new(resource_id: resource_id)
      # end

      # # Determines the download URI for the specified resource. Called after the record is harvested
      # # for discovery.
      # # @param resource [StashEngine::Resource] the resource
      # # @param record_identifier [String] the harvested record identifier (repository- or protocol-dependent)
      # def download_uri_for(record_identifier:)
      #   merritt_host = APP_CONFIG[:repository][:domain]
      #   ark = ark_from(record_identifier)
      #   "#{merritt_host}/d/#{ERB::Util.url_encode(ark)}"
      # end
      #
      # # Determines the update URI for the specified resource. Called after the record is harvested
      # # for discovery.
      # # @param resource [StashEngine::Resource] the resource
      # # @param record_identifier [String] the harvested record identifier (repository- or protocol-dependent)
      # def update_uri_for(resource:, record_identifier:) # rubocop:disable Lint/UnusedMethodArgument
      #   sword_endpoint = APP_CONFIG[:repository][:endpoint]
      #   doi = resource.identifier_str
      #   edit_uri_base = sword_endpoint.sub('/collection/', '/edit/')
      #   "#{edit_uri_base}/#{ERB::Util.url_encode(doi)}"
      # end

      # # Returns a logger
      # # @return [Logger] a logger
      # def logger
      #   Rails.logger
      # end

      # Calls {#create_submission_job} to create a submission job,
      # and executes it in the background using {Concurrent#global_io_executor},
      # "a global thread pool optimized for long, blocking (IO) tasks",
      # updates the resource state and sends notification email based
      # on the result.
      # @param resource_id [Integer] the ID of the resource
      def submit(resource_id:)
        res = StashEngine::Resource.find(resource_id)
        res.current_state = 'processing'
        resource_submission_service = Submission::ResourcesService.new(resource_id)

        if resource_submission_service.hold_submissions?
          resource_submission_service.update_repo_queue_state(resource_id: resource_id, state: 'rejected_shutting_down')
          return
        end
        resource_submission_service.update_repo_queue_state(resource_id: resource_id, state: 'enqueued')
        # promise = submission_job.submit_async(executor: @executor)
        Submission::SubmissionJob.perform_async(resource_id)

        # promise.on_success do |result|
        #   # deferred submissions are considered a success for our purposes (ie, qualified/probable success) and have
        #   # deferred? set on the submission_result object to indicate their odd status
        #   result.success? ? handle_success(result) : handle_failure(result)
        # end
        # promise.rescue do |reason|
        #   handle_failure(SubmissionResult.new(resource_id: resource_id, request_desc: submission_job.description, error: reason))
        # end
      end

      # # Register that a dataset has completed processing into the storage system
      # # TODO: rename this... "harvested" is a weird term left over from old versions of this system
      # def harvested(resource:)
      #   return unless resource.present?
      #   return unless resource == resource.identifier&.processing_resource
      #
      #   resource.download_uri = resource.s3_dir_name(type: 'data')
      #   resource.current_state = 'submitted'
      #   resource.save
      # end

      # # this will be called after merritt_status confirms successful ingest
      # def cleanup_files(resource)
      #   remove_public_dir(resource) # where the local manifest file is stored
      #   remove_submission_data_files(resource)
      # rescue StandardError => e
      #   msg = "An unexpected error occurred when cleaning up files for resource #{resource.id}: "
      #   msg << e.full_message
      #   logger.warn(msg)
      # end

      def self.update_repo_queue_state(resource_id:, state:)
        StashEngine::RepoQueueState.create(resource_id: resource_id, hostname: hostname, state: state)
      end

      # detect if we should be holding submissions because a hold-submissions.txt file exists one directory above Rails.root
      # def self.hold_submissions?
      #   File.exist?(File.expand_path(File.join(Rails.root, '..', 'hold-submissions.txt')))
      # end

      private

      # def ark_from(record_identifier)
      #   ark_match_data = record_identifier && record_identifier.match(ARK_PATTERN)
      #   raise ArgumentError, "No ARK found in record identifier #{record_identifier || 'nil'}" unless ark_match_data
      #
      #   ark_match_data[0].strip
      # end

      # def get_download_uri(resource, record_identifier)
      #   download_uri_for(record_identifier: record_identifier)
      # rescue StandardError => e
      #   raise ArgumentError, "Unable to determine download URI for resource #{resource.id} from record identifier #{record_identifier}: #{e}"
      # end
      #
      # def get_update_uri(resource, record_identifier)
      #   update_uri_for(resource: resource, record_identifier: record_identifier)
      # rescue StandardError => e
      #   raise ArgumentError, "Unable to determine update URI for resource #{resource.id} from record identifier #{record_identifier}: #{e}"
      # end

      # def handle_success(result)
      #   result.log_to(logger)
      #   update_submission_log(result)
      #
      #   # don't set new queue state on deferred submission results until the merrit_status checker does it for us, it's still
      #   # in progress until that happens.
      #   self.class.update_repo_queue_state(resource_id: result.resource_id, state: 'provisional_complete') unless result.deferred?
      # rescue StandardError => e
      #   # errors here don't constitute a submission failure, so we don't change the resource state
      #   log_error(e)
      # end

      # def handle_failure(result)
      #   result.log_to(logger)
      #   update_submission_log(result)
      #   self.class.update_repo_queue_state(resource_id: result.resource_id, state: 'errored')
      #   resource = StashEngine::Resource.find(result.resource_id)
      #   StashEngine::UserMailer.error_report(resource, result.error).deliver_now
      # rescue StandardError => e
      #   log_error(e)
      # ensure
      #   resource.current_state = 'error' if resource.present?
      # end

      # def log_error(error)
      #   logger.error(error.full_message)
      # end

      # def remove_if_exists(file)
      #   return if file.blank?
      #
      #   FileUtils.remove_entry_secure(file, true)
      # end

      # def remove_public_dir(resource)
      #   res_public_dir = Rails.public_path.join('system').join(resource.id.to_s)
      #   remove_if_exists(res_public_dir)
      # end
      #
      # def remove_submission_data_files(resource)
      #   Stash::Aws::S3.new.delete_dir(s3_key: resource.s3_dir_name(type: 'manifest').to_s)
      #   Stash::Aws::S3.new.delete_dir(s3_key: resource.s3_dir_name(type: 'data').to_s)
      # end

      # def update_submission_log(result)
      #   StashEngine::SubmissionLog.create(
      #     resource_id: result.resource_id,
      #     archive_submission_request: result.request_desc,
      #     archive_response: result.message || result.error.to_s
      #   )
      # end
    end
  end
end
