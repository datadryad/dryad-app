class ChangeFilenameCollaction < ActiveRecord::Migration
  def up
    remove_index :stash_engine_file_uploads, name: 'index_stash_engine_file_uploads_on_upload_file_name'
    execute <<-SQL
      ALTER TABLE stash_engine_file_uploads MODIFY
      upload_file_name TEXT
      CHARACTER SET utf8mb4 COLLATE utf8mb4_bin
    SQL
    add_index :stash_engine_file_uploads, :upload_file_name, length: 100
  end

  def down
    remove_index :stash_engine_file_uploads, name: 'index_stash_engine_file_uploads_on_upload_file_name'
    execute <<-SQL
      ALTER TABLE stash_engine_file_uploads MODIFY
      upload_file_name VARCHAR(255)
      CHARACTER SET utf8
      COLLATE utf8_unicode_ci
    SQL
    add_index :stash_engine_file_uploads, :upload_file_name
  end
end
