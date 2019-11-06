class AddDigestToFileUploads < ActiveRecord::Migration
  def up
    add_column :stash_engine_file_uploads, :digest, :string
    execute <<-SQL
      ALTER TABLE stash_engine_file_uploads ADD digest_type
        enum('adler-32', 'crc-32', 'md2', 'md5', 'sha-1', 'sha-256', 'sha-384', 'sha-512');
    SQL
    add_column :stash_engine_file_uploads, :description, :text
  end

  def down
    remove_column :stash_engine_file_uploads, :digest, :string
    remove_column :stash_engnie_file_uploads, :digest_type, :enum
    remove_column :stash_engine_file_uploads, :description, :text
  end
end
