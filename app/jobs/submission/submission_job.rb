module Submission
  class SubmissionJob < Submission::BaseJob
    include Sidekiq::Worker
    sidekiq_options queue: :submission, retry: 0, lock: :until_and_while_executing

    attr_reader :resource_id, :service

    def perform(resource_id)
      pp "Submitting resource #{resource_id}"
      @resource_id = resource_id
      @resource = StashEngine::Resource.find(resource_id)
      @service = Submission::ResourcesService.new(resource_id)

      if service.hold_submissions?
        resource.update_repo_queue_state(state: 'rejected_shutting_down')
        return
      end

      resource.update_repo_queue_state(state: 'enqueued')
      submit_resource
    end

    private

    def submit_resource
      Rails.logger.info("#{Time.now.xmlschema} #{description}")
      previously_submitted = StashEngine::RepoQueueState.where(resource_id: resource_id, state: 'processing').count.positive?
      if previously_submitted
        # Do not send to the repo again if it has already been sent. If we need to re-send we'll have to delete the statuses
        # and re-submit manually.  This should be an exceptional case that we send the same resource more than once.
        latest_queue = StashEngine::RepoQueueState.latest(resource_id: resource_id)
        latest_queue.destroy if latest_queue&.state == 'enqueued'
        return
      end

      service.submit
    rescue StandardError => e
      handle_failure(
        Stash::Repo::SubmissionResult.failure(resource_id: resource_id, request_desc: description, error: e)
      )
    end
  end
end
