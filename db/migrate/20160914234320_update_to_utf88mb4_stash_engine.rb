class UpdateToUtf88mb4StashEngine < ActiveRecord::Migration

  TABLES = %w{ searches stash_engine_identifiers stash_engine_resources stash_engine_submission_logs stash_engine_users
                stash_engine_versions }

  def up
    TABLES.each{|t| set_utf8mb4(t) }
    execute <<-SQL
      ALTER TABLE stash_engine_file_uploads MODIFY
      upload_content_type VARCHAR(255)
      CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci
    SQL
    execute <<-SQL
      ALTER TABLE stash_engine_file_uploads MODIFY
      temp_file_path TEXT
      CHARACTER SET utf8mb4 COLLATE utf8mb4_bin
    SQL
  end

  def down
    TABLES.each{|t| set_utf8(t) }
    execute <<-SQL
      ALTER TABLE stash_engine_file_uploads MODIFY
      upload_content_type VARCHAR(255)
      CHARACTER SET utf8 COLLATE utf8_unicode_ci
    SQL
    execute <<-SQL
      ALTER TABLE stash_engine_file_uploads MODIFY
      temp_file_path TEXT
      CHARACTER SET utf8 COLLATE utf8_unicode_ci
    SQL
  end

  private

  def set_utf8mb4(table_name)
    execute <<-SQL
      ALTER TABLE #{table_name} CONVERT TO CHARACTER SET utf8mb4
      COLLATE utf8mb4_unicode_ci;
    SQL
  end

  def set_utf8(table_name)
    execute <<-SQL
      ALTER TABLE #{table_name} CONVERT TO CHARACTER SET utf8
      COLLATE utf8_unicode_ci;
    SQL
  end
end
