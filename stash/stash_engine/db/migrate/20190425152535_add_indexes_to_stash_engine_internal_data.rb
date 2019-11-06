class AddIndexesToStashEngineInternalData < ActiveRecord::Migration
  def change
    add_index :stash_engine_internal_data, %i[data_type value]
  end
end
