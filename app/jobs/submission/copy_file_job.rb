module Submission
  class CopyFileJob
    include Sidekiq::Worker
    sidekiq_options queue: :submission_file, lock: :until_and_while_executing, retry: 1

    def perform(file_id)
      file = StashEngine::DataFile.find(file_id)
      begin
        Timeout.timeout(1.day) do
          Submission::FilesService.new(file).copy_file
          Submission::CheckStatusJob.perform_in(5.seconds, file.resource_id)
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
      end
    end
  end
end
