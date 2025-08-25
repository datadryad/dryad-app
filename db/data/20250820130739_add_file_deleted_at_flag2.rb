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
        ids = resource.previous_resources(include_self: true).pluck(:id)
        StashEngine::GenericFile.where(resource_id: ids).update(file_deleted_at: Time.current)
        StashEngine::GenericFile.where(resource_id: ids, file_state: 'created').update(file_state: 'deleted')
      end
    end
  end

  def down
    # raise ActiveRecord::IrreversibleMigration
  end
end
