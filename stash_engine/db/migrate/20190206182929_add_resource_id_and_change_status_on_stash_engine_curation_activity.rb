class AddResourceIdAndChangeStatusOnStashEngineCurationActivity < ActiveRecord::Migration
  def change
    add_column :stash_engine_curation_activities, :resource_id, :integer
    rename_column :stash_engine_curation_activities, :status, :old_status
    add_column :stash_engine_curation_activities, :status, :integer, default: 0
  end
end
