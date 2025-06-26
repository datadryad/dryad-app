module Submission
  class SubmissionJob
    include Sidekiq::Worker
    sidekiq_options queue: :submission, retry: 4

    attr_reader :resource_id, :resource, :service

    def perform(resource_id)
      @resource_id = resource_id
      @resource = StashEngine::Resource.find(resource_id)
      @service = Submission::ResourcesService.new(resource_id)

      if service.hold_submissions?
        service.update_repo_queue_state(state: 'rejected_shutting_down')
        return
      end

      service.update_repo_queue_state(state: 'enqueued')
      submit_resource
    end

    private

    def submit_resource
      Rails.logger.info("#{Time.now.xmlschema} #{description}")
      previously_submitted = StashEngine::RepoQueueState.where(resource_id: resource_id, state: 'processing').count.positive?
      if service.hold_submissions?
        # to mark that it needs to be re-enqueued and processed later
        service.update_repo_queue_state(state: 'rejected_shutting_down')
      elsif previously_submitted
        # Do not send to the repo again if it has already been sent. If we need to re-send we'll have to delete the statuses
        # and re-submit manually.  This should be an exceptional case that we send the same resource more than once.
        latest_queue = StashEngine::RepoQueueState.latest(resource_id: resource_id)
        latest_queue.destroy if latest_queue&.state == 'enqueued'
      else
        service.submit
      end
    rescue StandardError => e
      service.handle_failure(
        Stash::Repo::SubmissionResult.failure(resource_id: resource_id, request_desc: description, error: e)
      )
    end

    # Describes this submission job. This may include the resource ID, the type
    # of submission (create vs. update), and any configuration information (repository
    # URLs etc.) useful for debugging, but should not include any secret information
    # such as repository credentials, as it will be logged.
    # return [String] a description of the job
    def description
      @description ||= begin
        description_for(resource)
      rescue StandardError => e
        Rails.logger.error("Can't find resource #{resource_id}: #{e}\n#{e.full_message}\n")
        "#{self.class} for missing resource #{resource_id}"
      end
    end

    def description_for(resource)
      "#{self.class} for resource #{resource_id} (#{resource.identifier_str}): posting update to storage"
    end
  end
end
