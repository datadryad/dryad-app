class AddOldResourceIdToStashEngineResources < ActiveRecord::Migration
  def change
    add_column :stash_engine_resources, :old_resource_id, :integer
  end
end
