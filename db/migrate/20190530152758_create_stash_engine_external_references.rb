class CreateStashEngineExternalReferences < ActiveRecord::Migration[4.2]
  def change
    create_table :stash_engine_external_references do |t|
      t.integer :identifier_id, index: true
      t.string :source, index: true
      t.text :value
      t.timestamps
    end
  end
end
