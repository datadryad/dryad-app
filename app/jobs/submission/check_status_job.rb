module Submission
  class CheckStatusJob < Submission::BaseJob
    include Sidekiq::Worker
    sidekiq_options queue: :submission_check, retry: 2

    def perform(resource_id)
      @resource = StashEngine::Resource.find(resource_id)
      queue = resource.repo_queue_states.last
      return unless queue.state.in?(%w[processing provisional_complete])

      if queue.possibly_set_as_completed
        handle_success(
          Stash::Repo::SubmissionResult.success(resource_id: resource_id, request_desc: description, message: 'Success')
        )
        Rails.logger.info("  Resource #{queue.resource_id} available in storage and finalized")
        remove_redis_key
      else
        Rails.logger.info("  Resource #{queue.resource_id} not yet available")
      end
    end
  end
end
