class AddUtf8Mb4ToFilePath < ActiveRecord::Migration
  def change
    def up
      execute <<-SQL
      ALTER TABLE stash_engine_file_uploads MODIFY
      temp_file_path TEXT
      CHARACTER SET utf8mb4 COLLATE utf8mb4_bin
      SQL
    end

    def down
      execute <<-SQL
      ALTER TABLE stash_engine_file_uploads MODIFY
      temp_file_path TEXT
      CHARACTER SET utf8
      COLLATE utf8_unicode_ci
      SQL
    end
  end
end
