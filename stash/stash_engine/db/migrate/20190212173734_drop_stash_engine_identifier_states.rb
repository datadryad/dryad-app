class DropStashEngineIdentifierStates < ActiveRecord::Migration
  def change
    drop_table :stash_engine_identifier_states
  end
end
