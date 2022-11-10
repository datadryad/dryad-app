require 'api_application_controller'
require_relative 'datasets_controller'

module StashApi
  class SubmissionQueueController < ApiApplicationController
    before_action :require_json_headers
    before_action :force_json_content_type
    before_action :doorkeeper_authorize!
    before_action :require_api_user
    before_action :require_superuser

    # gets the length of items waiting to process ie, queued or held with rejected_shutting_down
    def length
      # by default we should calculate the length as rejected_shutting_down and enqueued
      @queue_length = StashEngine::RepoQueueState.latest_per_resource.where(state: %w[enqueued rejected_shutting_down]).count
      @executor = StashEngine.repository.executor
      render json: { queue_length: @queue_length, executor_queue_length: @executor.queue_length }
    end
  end
end
