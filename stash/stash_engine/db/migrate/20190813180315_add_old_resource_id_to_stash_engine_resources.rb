class AddOldResourceIdToStashEngineResources < ActiveRecord::Migration[4.2]
  def change
    add_column :stash_engine_resources, :old_resource_id, :integer
  end
end
