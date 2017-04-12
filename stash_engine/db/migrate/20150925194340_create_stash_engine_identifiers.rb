class CreateStashEngineIdentifiers < ActiveRecord::Migration
  def change
    create_table :stash_engine_identifiers do |t|
      t.string :identifier
      t.string :identifier_type
      t.integer :resource_id

      t.timestamps null: false
    end
  end
end
