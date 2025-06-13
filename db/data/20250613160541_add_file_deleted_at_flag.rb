# frozen_string_literal: true

class AddFileDeletedAtFlag < ActiveRecord::Migration[8.0]
  def up
    removed_files_note = 'remove_abandoned_datasets CRON - removing data files from abandoned dataset'
    StashEngine::Resource.joins(:curation_activities).where(stash_engine_curation_activities: {note: removed_files_note}) do |resource|
      ids = resource.previous_resources(include_self: true).pluck(:id)
      StashEngine::GenericFile.where(id: ids).update(file_deleted_at: Time.current)
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
