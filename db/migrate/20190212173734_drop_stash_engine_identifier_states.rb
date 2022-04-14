class DropStashEngineIdentifierStates < ActiveRecord::Migration[4.2]
  def change
    drop_table :stash_engine_identifier_states
  end
end
