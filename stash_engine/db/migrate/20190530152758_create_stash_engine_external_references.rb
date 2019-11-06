class CreateStashEngineExternalReferences < ActiveRecord::Migration
  def change
    create_table :stash_engine_external_references do |t|
      t.integer :identifier_id, index: true
      t.string :source, index: true
      t.text :value
      t.timestamps
    end
  end
end
