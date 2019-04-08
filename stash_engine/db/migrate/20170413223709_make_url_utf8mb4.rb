class MakeUrlUtf8mb4 < ActiveRecord::Migration
  def up
    set_utf8mb4('stash_engine_file_uploads', 'url', 'utf8mb4_general_ci')
  end

  def down
    # nothing much since you could lose data going to smaller field (varchar) or only 3 bytes, so you
    # really shouldn't go down
  end

  private

  def set_utf8mb4(table_name, col_name, collation = 'utf8mb4_bin')
    warn "Table '#{table_name}' does not exist" unless table_exists?(table_name)
    return unless table_exists?(table_name)

    # index_exists? only seems to work if the index was created in rails migrations and index is named a certain way
    has_index = index_exists?(table_name.intern, col_name.intern)
    remove_index(table_name.intern, column: col_name.intern) if has_index
    execute <<-SQL
        ALTER TABLE #{table_name} MODIFY
        #{col_name} TEXT
        CHARACTER SET utf8mb4 COLLATE #{collation}
    SQL
    add_index(table_name.intern, col_name.intern, length: 50) if has_index
  end

end
