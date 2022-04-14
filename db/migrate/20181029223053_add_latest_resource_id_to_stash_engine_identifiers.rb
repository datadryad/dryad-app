class AddLatestResourceIdToStashEngineIdentifiers < ActiveRecord::Migration[4.2]
  def change
    add_column :stash_engine_identifiers, :latest_resource_id, :integer
    add_index :stash_engine_identifiers, :latest_resource_id
  end
end
