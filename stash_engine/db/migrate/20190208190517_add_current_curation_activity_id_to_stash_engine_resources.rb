class AddCurrentCurationActivityIdToStashEngineResources < ActiveRecord::Migration
  def change
    add_column :stash_engine_resources, :current_curation_activity_id, :integer

    add_index :stash_engine_curation_activities, [:resource_id, :id]
  end
end
