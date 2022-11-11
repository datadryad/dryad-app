module StashEngine
  class RepoQueueState < ApplicationRecord
    self.table_name = 'stash_engine_repo_queue_states'
    include StashEngine::Support::StringEnum

    belongs_to :resource

    # Explanation of statuses:  This will log all the statuses for the resource, so the final status is the current one.
    #
    # rejected_shutting_down -- The server is not accepting new submissions since it wants to shut down, but the user need not worry.
    #                           Controlled by the presence of a hold-submissions.txt file in the directory above Rails.root ("../")
    #                           This status can be held and be re-enqueued after the queue has cleared and the server restarts.
    #
    # enqueued               -- The item is in an internal queue, waiting to submit to the repo when a worker is available.
    #
    # processing             -- The item has been sent to Merritt and we do not have a Promise return status for the item yet (from Merritt-Sword)
    #
    # completed              -- A successful return status was received (from Merritt-Sword)
    #
    # errored                -- An unsuccessful return status was received (from Merritt-Sword).  See stash_engine_submission_logs and maybe
    #                           also server logs for details.

    enum_vals = %w[
      rejected_shutting_down
      enqueued
      processing
      completed
      errored
    ]
    string_enum('state', enum_vals, 'enqueued', false)

    # Validations
    # ------------------------------------------
    validates :resource, presence: true
    validates :state, presence: true, inclusion: { in: enum_vals }

    # Scopes
    # ------------------------------------------

    SUBQUERY_FOR_LATEST = <<~HEREDOC
      SELECT resource_id, max(id) as id
      FROM stash_engine_repo_queue_states
      GROUP BY resource_id
    HEREDOC
      .freeze

    scope :latest_per_resource, -> do
      joins("INNER JOIN (#{SUBQUERY_FOR_LATEST}) subque ON stash_engine_repo_queue_states.id = subque.id")
    end

    # This will not work correctly as a scope since Rails returns all records if it doesn't match one as a scope.  Wow.
    # Just wow. That is crazy bad design and violates the Principle of Least Surprise.
    # https://stackoverflow.com/questions/20942672/rails-scope-returns-all-instead-of-nil
    def self.latest(resource_id:)
      where(resource_id: resource_id).order(updated_at: :desc, id: :desc).first
    end

  end
end
