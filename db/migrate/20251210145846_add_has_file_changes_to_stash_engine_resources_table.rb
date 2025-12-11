class AddHasFileChangesToStashEngineResourcesTable < ActiveRecord::Migration[8.0]
  def change
    add_column :stash_engine_resources, :has_file_changes, :boolean, default: false
    add_index :stash_engine_resources, :has_file_changes
  end
end
