require 'rails'
require 'down'
require 'active_record'
require 'concurrent/promise'
require 'byebug'
require 'stash/aws/s3'

module Submission
  class SubmissionJob
    include Sidekiq::Worker
    sidekiq_options queue: :submission, retry: 4

    attr_reader :resource_id

    def perform(res_id)
      @resource_id = res_id
      @resource_id = resource_id.to_i if resource_id.is_a?(String)
      raise ArgumentError, "Invalid resource ID: #{resource_id || 'nil'}" unless resource_id.is_a?(Integer)

      service = Submission::ResourcesService.new(resource_id)
      Rails.logger.info("#{Time.now.xmlschema} #{description}")
      previously_submitted = StashEngine::RepoQueueState.where(resource_id: resource_id, state: 'processing').count.positive?
      if service.hold_submissions?
        # to mark that it needs to be re-enqueued and processed later
        Stash::Repo::Repository.update_repo_queue_state(resource_id: resource_id, state: 'rejected_shutting_down')
      elsif previously_submitted
        # Do not send to the repo again if it has already been sent. If we need to re-send we'll have to delete the statuses
        # and re-submit manually.  This should be an exceptional case that we send the same resource more than once.
        latest_queue = StashEngine::RepoQueueState.latest(resource_id: resource_id)
        latest_queue.destroy if latest_queue.present? && (latest_queue.state == 'enqueued')
      else
        # Stash::Repo::Repository.update_repo_queue_state(resource_id: @resource_id, state: 'processing')
        service.submit
      end
    rescue StandardError => e
      Stash::Repo::SubmissionResult.failure(resource_id: resource_id, request_desc: description, error: e)
    end

    private

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
        Rails.logger.error("Can't find resource #{resource_id}: #{e}\n#{e.full_message}\n")
        "#{self.class} for missing resource #{resource_id}"
      end
    end

    def description_for(resource)
      "#{self.class} for resource #{resource_id} (#{resource.identifier_str}): posting update to storage"
    end
  end
end
