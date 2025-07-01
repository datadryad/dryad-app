class AddFileDeletedAtToStashEngineGenericFiles < ActiveRecord::Migration[8.0]
  def change
    add_column :stash_engine_generic_files, :file_deleted_at, :datetime
    add_index :stash_engine_generic_files, :file_deleted_at
  end
end
