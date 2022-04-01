class AddIndexesToStashEngineInternalData < ActiveRecord::Migration[4.2]
  def change
    add_index :stash_engine_internal_data, %i[data_type value]
  end
end
