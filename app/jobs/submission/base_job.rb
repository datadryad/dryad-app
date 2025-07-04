module Submission
  class BaseJob

    attr_reader :resource

    def handle_success(result)
      result.log_to(Rails.logger)
      update_submission_log(result)

      # don't set new queue state on deferred submission results until the merrit_status checker does it for us, it's still
      # in progress until that happens.
      resource.update_repo_queue_state(state: 'provisional_complete') unless result.deferred?
    rescue StandardError => e
      # errors here don't constitute a submission failure, so we don't change the resource state
      Rails.logger.error(e.full_message)
    end

    def handle_failure(result)
      result.log_to(Rails.logger)
      update_submission_log(result)
      resource.update_repo_queue_state(state: 'errored')
      resource = StashEngine::Resource.find(result.resource_id)
      StashEngine::UserMailer.error_report(resource, result.error).deliver_now
    rescue StandardError => e
      Rails.logger.error(e.full_message)
      # raising the error so that the job remains stored in "Dead" queue
      raise e
    ensure
      resource.current_state = 'error' if resource.present?
      # raising the error so that the job remains stored in "Dead" queue
      raise result.error
    end

    private

    def update_submission_log(result)
      StashEngine::SubmissionLog.create(
        resource_id: result.resource_id,
        archive_submission_request: result.request_desc,
        archive_response: result.message || result.error.to_s
      )
    end

    # Describes this submission job. This may include the resource ID, the type
    # of submission (create vs. update), and any configuration information (repository
    # URLs etc.) useful for debugging, but should not include any secret information
    # such as repository credentials, as it will be logged.
    # return [String] a description of the job
    def description
      @description ||= "#{self.class} for resource #{resource.id} (#{resource.identifier_str}): posting update to storage"
    end
  end
end
