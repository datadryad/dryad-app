class AddResourceIdToResourceStates < ActiveRecord::Migration[4.2]
  def up
    add_column :stash_engine_resource_states, :resource_id, :integer
  end

  def down
    remove_column :stash_engine_resource_states, :resource_id
  end
end
