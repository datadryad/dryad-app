require 'stash/repo'
require 'stash/merritt/merritt_submission_job'

module Stash
  module Merritt
    class Repository < Stash::Repo::Repository

      def initialize(url_helpers:)
        super
      end

      def create_submission_job(resource_id:)
        MerrittSubmissionJob.new(resource_id: resource_id, url_helpers: url_helpers)
      end
    end
  end
end
