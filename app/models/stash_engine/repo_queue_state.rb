module StashEngine
  class RepoQueueState < ApplicationRecord
    self.table_name = 'stash_engine_repo_queue_states'
    include StashEngine::Concerns::StringEnum

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

    # does remote query to check if this queue state has been ingested into Merritt yet
    def available_in_merritt?
      mrt_results = resource&.identifier&.merritt_object_info
      return false unless mrt_results.present?

      # get the merritt versions available, which may not be the same version numbers as stash versions in some cases
      mrt_versions = mrt_results['versions'].map { |i| i['version_number'] }
      this_version = resource&.stash_version&.merritt_version
      return false unless this_version.present?

      return false unless mrt_versions.include?(this_version)

      true
    end

    def set_as_completed
      mrt_results = resource&.identifier&.merritt_object_info
      return unless mrt_results.present?

      this_version = resource&.stash_version&.merritt_version
      return unless mrt_results['versions'].map { |i| i['version_number'] }.include?(this_version)


      #doi = '<doi-here>' # bare doi like 10.15146/mdpr-pm59
      #merritt_id = 'http://n2t.net/ark:/<fill-correct-ark-here>' # this is the ARK at Merritt like http://n2t.net/ark:/13030/m58s9s7v
      #version = 2
      # it appears that the merritt_id is the record_identifier and the id is an identifier object?  Need to check that code
      # lib/stash/repo/repository calls stash-merritt/lib/stash/merritt/repository.rb and this populates download and update URIs into the db

      # identifier is full stash_engine_identifier model object, record_identifier is full url with ark:/383838/833838 on end
      # #{merritt_host}/d/#{ERB::Util.url_encode(ark)}
      # ARK_PATTERN = %r{ark:/[a-z0-9]+/[a-z0-9]+}.freeze
      StashEngine.repository.harvested(identifier: id, record_identifier: record_identifier)

      if StashEngine::RepoQueueState.where(resource_id: @resource_id, state: 'completed').count < 1
        StashEngine.repository.class.update_repo_queue_state(resource_id: @resource.id, state: 'completed')
      end

      # now that the OAI-PMH feed has confirmed it's in Merritt then cleanup, but not before
      ::StashEngine.repository.cleanup_files(@resource)

    end

    def update_size!
      return unless resource

      ds_info = Stash::Repo::DatasetInfo.new(id)
      id.update(storage_size: ds_info.dataset_size)
      update_zero_sizes!(ds_info)
    end

    def update_zero_sizes!(ds_info_obj)
      return unless resource

      resource.data_files.where(upload_file_size: 0).where(file_state: 'created').each do |f|
        f.update(upload_file_size: ds_info_obj.file_size(f.upload_file_name))
      end
    end

  end
end
