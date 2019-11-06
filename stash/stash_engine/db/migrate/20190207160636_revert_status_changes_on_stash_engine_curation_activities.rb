class RevertStatusChangesOnStashEngineCurationActivities < ActiveRecord::Migration
  def change
    remove_column :stash_engine_curation_activities, :status
    rename_column :stash_engine_curation_activities, :old_status, :status
    change_column :stash_engine_curation_activities, :status, :string, default: 'in_progress'
  end
end
