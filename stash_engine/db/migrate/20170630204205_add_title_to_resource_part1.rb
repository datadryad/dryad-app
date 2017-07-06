class AddTitleToResourcePart1 < ActiveRecord::Migration
  def up
    add_utf8mb4('stash_engine_resources', 'title')
  end

  def down
    remove_column :stash_engine_resources, :title
  end

  private

  def add_utf8mb4(table_name, col_name, collation = 'utf8mb4_unicode_ci')
    warn "Table '#{table_name}' does not exist" unless table_exists?(table_name)
    return unless table_exists?(table_name)
    execute <<-SQL
        ALTER TABLE #{table_name} ADD
        #{col_name} TEXT
        CHARACTER SET utf8mb4 COLLATE #{collation}
    SQL
  end
end
