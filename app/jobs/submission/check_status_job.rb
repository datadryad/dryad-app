require 'rails'
require 'down'
require 'active_record'
require 'concurrent/promise'
require 'byebug'
require 'stash/aws/s3'

module Submission
  class CheckStatusJob
    include Sidekiq::Worker
    sidekiq_options queue: :submission_check, lock: :until_executed, retry: 5

    def perform(resource_id)
      resource = StashEngine::Resource.find(resource_id)
      pp queue = resource.repo_queue_states.last
      pp queue.state
      return unless queue.state.in?(%w[processing provisional_complete])

      if queue.possibly_set_as_completed
        Rails.logger.info("  Resource #{queue.resource_id} available in storage and finalized")
      elsif queue.updated_at < 1.day.ago # older than 1 day ago
        Rails.logger.info("  Resource #{queue.resource_id} has been processing for more than a day, so marking as errored")
        StashEngine::RepoQueueState.create(resource_id: queue.resource_id, state: 'errored')
        exception = StandardError.new('item has been processing for more than a day, so marking as errored')
        exception.set_backtrace(caller)
        StashEngine::UserMailer.error_report(queue.resource, exception).deliver_now
      else
        Rails.logger.info("  Resource #{queue.resource_id} not yet available")
      end
    end
  end
end
