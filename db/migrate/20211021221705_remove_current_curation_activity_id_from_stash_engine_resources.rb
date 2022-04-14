class RemoveCurrentCurationActivityIdFromStashEngineResources < ActiveRecord::Migration[5.2]
  def up
    remove_column :stash_engine_resources, :current_curation_activity_id
  end

  def down
    add_column :stash_engine_resources, :current_curation_activity_id, :integer
  end
end
