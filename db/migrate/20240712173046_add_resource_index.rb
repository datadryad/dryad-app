class AddResourceIndex < ActiveRecord::Migration[7.0]
  def change
    add_index :stash_engine_resources, [:identifier_id, :created_at], unique: true
  end
end
