class AddIndexToStashEngineInternalData < ActiveRecord::Migration
  def change
    add_index :stash_engine_internal_data, :identifier_id
  end
end
