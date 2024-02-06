# == Schema Information
#
# Table name: stash_engine_repo_queue_states
#
#  id          :integer          not null, primary key
#  hostname    :string(191)
#  state       :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  resource_id :integer
#
# Indexes
#
#  index_stash_engine_repo_queue_states_on_resource_id  (resource_id)
#

require 'stash/aws/s3'

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

    # Check if this queue state has been ingested into storage yet
    def available_in_storage?
      return false unless resource.data_files.present?

      puts "Checking storage status of resource #{resource_id}"
      s3 = Stash::Aws::S3.new(s3_bucket_name: APP_CONFIG[:s3][:merritt_bucket])

      # see if all files created for this resource/version are available in the v3 structure with the expected size
      # Note: this doesn't walk the version history -- it only checks the files created for the current version
      resource.data_files.where(file_state: 'created').each do |data_file|
        puts "checking #{data_file.upload_file_name}"
        return false if data_file.digest.nil?

        permanent_key = "v3/#{data_file.s3_staged_path}"
        puts " -- exist? #{s3.exists?(s3_key: permanent_key)}"
        return false unless s3.exists?(s3_key: permanent_key)

        puts " -- size #{s3.size(s3_key: permanent_key)} -- #{data_file.upload_file_size}"
        return false unless s3.size(s3_key: permanent_key) == data_file.upload_file_size
      end

      true
    end

    # also returns true/false on success/error so we don't have to call the storage check twice
    # (once to get status and once to do the completion)
    def possibly_set_as_completed
      # this is a guard against setting something completed that isn't and that will make this method fail
      return false unless resource.present? && available_in_storage?

      StashEngine.repository.harvested(resource: resource)
      if StashEngine::RepoQueueState.where(resource_id: resource_id, state: 'completed').count < 1
        StashEngine.repository.class.update_repo_queue_state(resource_id: resource_id, state: 'completed')
      end

      id = resource.identifier
      total_dataset_size = 0
      resource.data_files.each do |data_file|
        total_dataset_size += data_file.upload_file_size
      end
      id.update(storage_size: total_dataset_size)
      ::StashEngine.repository.cleanup_files(resource)
      true
    end

  end
end
