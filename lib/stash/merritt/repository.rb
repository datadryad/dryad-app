require 'stash/repo'
require 'stash/merritt/submission_job'

module Stash
  module Merritt
    class Repository < Stash::Repo::Repository

      def initialize(url_helpers:)
        super
      end

      def create_submission_job(resource_id:)
        SubmissionJob.new(resource_id: resource_id, url_helpers: url_helpers)
      end
    end
  end
end
