class AddDatabaseIndexes < ActiveRecord::Migration[7.0]
  def change
    add_index :stash_engine_generic_files, :status_code
  end
end
