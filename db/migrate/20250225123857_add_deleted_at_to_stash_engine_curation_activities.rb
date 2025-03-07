class AddDeletedAtToStashEngineCurationActivities < ActiveRecord::Migration[8.0]
  def change
    add_column :stash_engine_curation_activities, :deleted_at, :datetime
    add_index :stash_engine_curation_activities, :deleted_at
  end
end
