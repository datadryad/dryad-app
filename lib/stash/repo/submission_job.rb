require 'rails'
require 'active_record'
require 'concurrent/promise'
require 'byebug'

module Stash
  module Repo
    # Superclass of background tasks. Should not contain any thread-unsafe
    # data or any data that cannot be serialized (e.g. pass database IDs, not
    # ActiveRecord models). The state of ActiveRecord models outside the lifetime
    # of the `submit!` method is not guaranteed.
    class SubmissionJob
      attr_reader :resource_id

      def initialize(resource_id:)
        resource_id = resource_id.to_i if resource_id.is_a?(String)
        raise ArgumentError, "Invalid resource ID: #{resource_id || 'nil'}" unless resource_id.is_a?(Integer)

        @resource_id = resource_id
      end

      # Executes this task and returns a result, or throws an error. Any ActiveRecord
      # models needed by the task should be created in this method, and should not
      # be returned, yielded, thrown, or passed outside it.
      # this is where it actually starts running the real submission whenever it activates from the promise
      #
      # @return [SubmissionResult] the result of the task.
      def submit!
        logger.info("#{Time.now.xmlschema} #{description}")
        previously_submitted = StashEngine::RepoQueueState.where(resource_id: @resource_id, state: 'processing').count.positive?
        if Stash::Repo::Repository.hold_submissions?
          # to mark that it needs to be re-enqueued and processed later
          Stash::Repo::Repository.update_repo_queue_state(resource_id: @resource_id, state: 'rejected_shutting_down')
        elsif previously_submitted
          # Do not send to the repo again if it has already been sent. If we need to re-send we'll have to delete the statuses
          # and re-submit manually.  This should be an exceptional case that we send the same resource to Merritt more than once.
          latest_queue = StashEngine::RepoQueueState.latest(resource_id: @resource__id)
          latest_queue.destroy if latest_queue.present? && (latest_queue.state == 'enqueued')
        else
          Stash::Repo::Repository.update_repo_queue_state(resource_id: @resource_id, state: 'processing')
          do_submit!
        end
      rescue StandardError => e
        Stash::Repo::SubmissionResult.failure(resource_id: resource_id, request_desc: description, error: e)
      end

      # Describes this submission job. This may include the resource ID, the type
      # of submission (create vs. update), and any configuration information (repository
      # URLs etc.) useful for debugging, but should not include any secret information
      # such as repository credentials, as it will be logged.
      # return [String] a description of the job
      def description
        @description ||= begin
          resource = StashEngine::Resource.find(resource_id)
          description_for(resource)
        rescue StandardError => e
          logger.error("Can't find resource #{resource_id}: #{e}\n#{e.full_message}\n")
          "#{self.class} for missing resource #{resource_id}"
        end
      end

      # Executes this task asynchronously and with its own ActiveRecord connection.
      # @return [Promise<SubmissionResult>] a Promise that will provide the result of this job
      def submit_async(executor:)
        Concurrent::Promise.new(executor: executor) { ActiveRecord::Base.connection_pool.with_connection { submit! } }.execute
      end

      def logger
        Rails.logger
      end

      private

      def do_submit!
        package = create_package
        result_str = submit(package)
        Stash::Repo::SubmissionResult.success(resource_id: resource_id, request_desc: description, message: 'Success')
        Stash::Repo::SubmissionResult
          .success(resource_id: resource_id, request_desc: description, message: "Submitted to Merritt for asynchronous completion\n#{result_str}")
      end

      def resource
        @resource ||= StashEngine::Resource.find(resource_id)
      end

      # :nocov:
      def tenant
        @tenant ||= resource.tenant
      end
      # :nocov:

      def id_helper
        @id_helper ||= Stash::Doi::DataciteGen.new(resource: resource)
      end

      def create_package
        id_helper.ensure_identifier
        log_info("creating package for resource #{resource_id} (#{resource.identifier_str})")
        ObjectManifestPackage.new(resource: resource)
      end

      def submit(package)
        log_info("submitting resource #{resource_id} (#{resource.identifier_str})")
        merritt_helper = MerrittHelper.new(package: package, logger: logger)
        merritt_helper.submit!
      end

      def description_for(resource)
        msg = "#{self.class} for resource #{resource_id} (#{resource.identifier_str}): "
        msg << if (update_uri = resource.update_uri)
                 "posting update to #{update_uri}"
               else
                 "posting new object to #{Stash::Repo::MerrittHelper.sword_params[:collection_uri]}"
               end
        msg << " (tenant: #{resource.tenant_id})"
      end

      def log_info(message)
        logger.info("#{Time.now.xmlschema} #{self.class}: #{message}")
      end

    end
  end
end
