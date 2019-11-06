class UpdateToUtf88mb4StashEngine < ActiveRecord::Migration

  TABLES = { 'searches' => %w[query_params],
             'stash_engine_identifiers' => %w[identifier identifier_type],
             'stash_engine_resources' => %w[download_uri update_uri],
             'stash_engine_submission_logs' => %w[archive_response archive_submission_request],
             'stash_engine_users' => %w[first_name last_name email uid provider oauth_token tenant_id],
             'stash_engine_versions' => %w[zip_filename] }.freeze

  def up
    TABLES.each do |table, v|
      v.each do |column|
        set_utf8mb4(table, column)
      end
    end
    set_utf8mb4('stash_engine_file_uploads', 'upload_content_type')
    set_utf8mb4('stash_engine_file_uploads', 'temp_file_path', 'utf8mb4_bin')
  end

  def down
    # nothing much since you could lose data going to smaller field (varchar) or only 3 bytes, so you
    # really shouldn't go down
  end

  private

  def set_utf8mb4(table_name, col_name, collation = 'utf8mb4_unicode_ci')
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
