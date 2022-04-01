class AddIndexToStashEngineInternalData < ActiveRecord::Migration[4.2]
  def change
    add_index :stash_engine_internal_data, :identifier_id
  end
end
