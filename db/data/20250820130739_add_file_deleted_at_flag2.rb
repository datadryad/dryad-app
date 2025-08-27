# frozen_string_literal: true

class AddFileDeletedAtFlag2 < ActiveRecord::Migration[8.0]
  def up
    removed_files_note = 'remove_abandoned_datasets CRON - removing data files from abandoned dataset'
    StashEngine::Resource.joins(:curation_activities).where(stash_engine_curation_activities: {note: removed_files_note}).each do |resource|
      if resource.id == resource.identifier.latest_resource.id
        # create a new version to mark all files as deleted
        new_res = DuplicateResourceService.new(resource, StashEngine::User.system_user).call
        new_res.update skip_emails: true
        new_res.generic_files.update(file_deleted_at: Time.current, file_state: 'deleted')
        new_res.current_state = 'submitted'

        # Record the file deletion
        StashEngine::CurationActivity.create(
          resource_id: new_res.id,
          user_id: 0,
          status: 'withdrawn',
          note: 'remove_abandoned_datasets CRON - mark files as deleted',
          skip_emails: true
        )
      else
        # mark all files as deleted in next resource
        next_resource = resource.identifier.resources.where('id > ?', resource.id).order(id: :asc).first
        next if next_resource.nil?
        next if next_resource.curation_activities.where(note: 'remove_abandoned_datasets CRON - mark files as deleted').present?

        deleted_files = next_resource.generic_files.where(file_state: 'copied')
        deleted_files.update(file_state: 'deleted', file_deleted_at: next_resource.created_at)
        # create log entry so we know the files were marked as deleted
        next_resource.curation_activities.create(
          status: next_resource.current_curation_status,
          note: 'remove_abandoned_datasets CRON - mark files as deleted',
          user_id: 0
        )

        # delete files marked as deleted in all following resources
        following_resources = resource.identifier.resources.where('id > ?', next_resource.id)
        next if following_resources.empty?

        StashEngine::GenericFile.where(resource_id: following_resources.ids, file_state: 'copied', original_filename: deleted_files.pluck(:original_filename)).destroy_all
      end
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
