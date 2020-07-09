class CreateOriginalUrlAndService < ActiveRecord::Migration
  def up
    add_utf8mb4('stash_engine_file_uploads', 'original_url', 'utf8mb4_general_ci')
    add_column :stash_engine_file_uploads, :cloud_service, :string
  end

  def down
    remove_column :stash_engine_file_uploads, :original_url
    remove_column :stash_engine_file_uploads, :cloud_service
  end

  private

  def add_utf8mb4(table_name, col_name, collation = 'utf8mb4_bin')
    warn "Table '#{table_name}' does not exist" unless table_exists?(table_name)
    return unless table_exists?(table_name)

    execute <<-SQL
        ALTER TABLE #{table_name} ADD
        #{col_name} TEXT
        CHARACTER SET utf8mb4 COLLATE #{collation}
    SQL
  end
end
