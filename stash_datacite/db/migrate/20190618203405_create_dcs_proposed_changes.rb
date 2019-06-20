class CreateDcsProposedChanges < ActiveRecord::Migration
  def change
    create_table :dcs_proposed_changes do |t|
      t.references :identifier_id, index: true
      t.string :publication_issn, index: true
      t.string :publication_doi, index: true
      t.float :score
      t.string :title
      t.text :authors
      t.datetime :publication_date
      t.boolean :approved
      t.references :approved_by_id, index: true
      t.string :provenance
      t.timestamps null: false
    end
  end
end
