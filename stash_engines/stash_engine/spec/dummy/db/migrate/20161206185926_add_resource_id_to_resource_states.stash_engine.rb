# This migration comes from stash_engine (originally 20160318035403)
class AddResourceIdToResourceStates < ActiveRecord::Migration
  def up
    add_column :stash_engine_resource_states, :resource_id, :integer
  end

  def down
    remove_column :stash_engine_resource_states, :resource_id
  end
end