class IndexResourceIdOnStashEngineResourceStates < ActiveRecord::Migration[5.2]
  def change
    add_index :stash_engine_resource_states, :resource_id
  end
end
