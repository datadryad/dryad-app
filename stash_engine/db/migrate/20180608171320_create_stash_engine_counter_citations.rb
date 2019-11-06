class CreateStashEngineCounterCitations < ActiveRecord::Migration
  def change
    create_table :stash_engine_counter_citations do |t|
      t.references :identifier
      t.text :citation
      t.text :doi

      t.index :doi, length: 20

      t.timestamps null: false
    end
  end
end
