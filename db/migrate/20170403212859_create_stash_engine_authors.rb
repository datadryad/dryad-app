class CreateStashEngineAuthors < ActiveRecord::Migration
  def change
    create_table :stash_engine_authors do |t|
      t.string :author_first_name
      t.string :author_last_name
      t.string :author_email
      t.string :author_orcid
      t.integer :resource_id

      t.timestamps null: false
    end

    add_index(:stash_engine_authors, :resource_id)
    add_index(:stash_engine_authors, :author_orcid, length: { author_orcid: 20 })
  end
end
