class CreateStashEngineInternalData < ActiveRecord::Migration[4.2]
  def change
    create_table :stash_engine_internal_data do |t|
      t.references :resource
      t.string :data_type
      t.string :value

      t.timestamps null: false
    end
  end
end
