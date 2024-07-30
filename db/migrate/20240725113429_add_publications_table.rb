class AddPublicationsTable < ActiveRecord::Migration[7.0]
  def change
    create_table :stash_engine_resource_publications do |t|
      t.integer :resource_id, index: { unique: true }
      t.string :publication_name
      t.string :publication_issn
      t.string :manuscript_number
      t.timestamps
    end
    add_foreign_key :stash_engine_resource_publications, :stash_engine_resources, column: :resource_id
  end
end
