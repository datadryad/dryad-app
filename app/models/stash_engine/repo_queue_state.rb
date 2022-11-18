module StashEngine
  class RepoQueueState < ApplicationRecord
    self.table_name = 'stash_engine_repo_queue_states'
    include StashEngine::Concerns::StringEnum

    attr_reader :mrt_results # this is for tests

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
    # provisional_complete   -- Merritt said it was accepted but we still haven't seen it appear in their system search
    #
    # completed              -- A successful return status was received (from Merritt-Sword)
    #
    # errored                -- An unsuccessful return status was received (from Merritt-Sword).  See stash_engine_submission_logs and maybe
    #                           also server logs for details.

    # a provisional complete means we got a message from SWORD saying it had been ingested but not searchable in Merritt yet
    enum_vals = %w[
      rejected_shutting_down
      enqueued
      processing
      completed
      errored
      provisional_complete
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

    # Does remote query to check if this queue state has been ingested into Merritt yet
    # Also sets @mrt_results as member variable so it can be reused without re-querying merritt again.
    def available_in_merritt?

      @mrt_results = resource&.identifier&.merritt_object_info
      return false unless @mrt_results.present?

      # get the merritt versions available, which may not be the same version numbers as stash versions in some cases
      mrt_versions = @mrt_results['versions'].map { |i| i['version_number'] }
      this_version = resource&.stash_version&.merritt_version
      return false unless this_version.present?

      return false unless mrt_versions.include?(this_version)

      true
    end

    # also returns true/false on success/error so we don't have to call the merritt api twice
    # (once to get status and once to do the completion)
    def provisional_set_as_completed
      # this is a guard against setting something completed that isn't and that will make this method fail
      return false unless available_in_merritt? # this also sets @mrt_results member variable so we don't have to redo the query again

      merritt_id = "#{resource.tenant.repository.domain}/d/#{@mrt_results['ark']}"
      StashEngine.repository.harvested(identifier: resource.identifier, record_identifier: merritt_id)

      if StashEngine::RepoQueueState.where(resource_id: resource_id, state: 'completed').count < 1
        StashEngine.repository.class.update_repo_queue_state(resource_id: resource_id, state: 'completed')
      end

      update_size!
      # now that the OAI-PMH feed has confirmed it's in Merritt then cleanup, but not before
      ::StashEngine.repository.cleanup_files(resource)
      true
    end

    # these "update" methods were moved from previous location in controller as post-processing steps
    private def update_size!
      return unless resource

      id = resource.identifier
      ds_info = Stash::Repo::DatasetInfo.new(id)
      id.update(storage_size: ds_info.dataset_size)
      update_zero_sizes!(ds_info)
    end

    private def update_zero_sizes!(ds_info_obj)
      return unless resource

      resource.data_files.where(upload_file_size: 0).where(file_state: 'created').each do |f|
        f.update(upload_file_size: ds_info_obj.file_size(f.upload_file_name))
      end
    end

  end
end
