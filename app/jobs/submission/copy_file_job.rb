module Submission
  class CopyFileJob < Submission::BaseJob
    include Sidekiq::Worker
    sidekiq_options queue: :submission_file, lock: :until_and_while_executing, retry: 1

    def perform(file_id)
      file = StashEngine::DataFile.find(file_id)
      @resource = file.resource

      begin
        Timeout.timeout(1.day) do
          pp "Uploading file #{file.id}"
          Submission::FilesService.new(file).copy_file
          ArchiveAnalyzerJob.perform_async(file.id) if file.archive? && file.file_state.in?(%w[created copied])

          set_submission_status
        end
      rescue Timeout::Error
        queue = file.resource.repo_queue_states.last
        message = "File #{file_id} for resource #{queue.resource_id} has been processing for more than a day, so marking as errored"
        Rails.logger.info(message)
        StashEngine::RepoQueueState.create(resource_id: queue.resource_id, state: 'errored')
        exception = StandardError.new(message)
        exception.set_backtrace(caller)
        StashEngine::UserMailer.error_report(queue.resource, exception).deliver_now
        raise exception
      rescue StandardError => e
        handle_failure(
          Stash::Repo::SubmissionResult.failure(resource_id: resource.id, request_desc: description, error: e)
        )
      end
    end
  end
end
