class CreateStashEngineManuscripts < ActiveRecord::Migration[5.2]
  def change
    create_table :stash_engine_manuscripts do |t|
      t.belongs_to :journal
      t.belongs_to :identifier, optional: true
      t.string :manuscript_number
      t.string :status
      t.text :metadata, limit: 16.megabytes - 1
      t.timestamps
    end
  end
end
