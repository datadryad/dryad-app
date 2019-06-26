class CreateStashEngineProposedChanges < ActiveRecord::Migration
  def change
    create_table :stash_engine_proposed_changes do |t|
      t.references :identifier, index: true
      t.boolean :approved
      t.references :user, index: true
      t.text :authors
      t.string :provenance
      t.datetime :publication_date
      t.string :publication_doi, index: true
      t.string :publication_name, index: true
      t.float :score
      t.string :title
      t.timestamps null: false
    end
  end
end
