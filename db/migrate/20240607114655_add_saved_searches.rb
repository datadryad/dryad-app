class AddSavedSearches < ActiveRecord::Migration[7.0]
  def change
    create_table :stash_engine_saved_searches do |t|
      t.integer :user_id
      t.string :type
      t.boolean :default
      t.string :title
      t.string :description
      t.string :share_code
      t.json :properties
      t.timestamps
    end
    add_index :stash_engine_saved_searches, [:user_id, :type]
    add_foreign_key :stash_engine_saved_searches, :stash_engine_users, column: :user_id
  end
end
