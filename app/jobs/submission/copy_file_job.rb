require 'rails'
require 'down'
require 'active_record'
require 'concurrent/promise'
require 'byebug'
require 'stash/aws/s3'

module Submission
  class CopyFileJob
    include Sidekiq::Worker
    sidekiq_options queue: :submission_file, lock: :until_executed, retry: 5

    def perform(file_id)
      file = StashEngine::DataFile.find(file_id)

      Submission::FilesService.new(file).submit
      Submission::CheckStatusJob.perform_async(file.resource_id)
    end
  end
end
