class UpdateToUtf8mb4StashDatacite < ActiveRecord::Migration

  TABLES = { 'dcs_affiliations' => %w[short_name long_name abbreviation],
             'dcs_alternate_identifiers' => %w[alternate_identifier alternate_identifier_type],
             'dcs_contributors' => %w[contributor_name award_number],
             'dcs_creators' => %w[creator_first_name creator_last_name],
             'dcs_descriptions' => %w[description],
             'dcs_formats' => %w[format],
             'dcs_geo_location_places' => %w[geo_location_place],
             'dcs_languages' => %w[language],
             'dcs_name_identifiers' => %w[name_identifier name_identifier_scheme scheme_URI],
             'dcs_publishers' => %w[publisher],
             'dcs_related_identifiers' => %w[related_identifier related_metadata_scheme scheme_URI scheme_type],
             'dcs_rights' => %w[rights rights_uri],
             'dcs_sizes' => %w[size],
             'dcs_subjects' => %w[subject subject_scheme scheme_URI] }.freeze

  def up
    TABLES.each do |table, v|
      v.each do |column|
        set_utf8mb4(table, column)
      end
    end
  end

  def down
    # nothing much since you could lose data going to smaller field (varchar) or only 3 bytes, so you
    # really shouldn't go down
  end

  private

  def set_utf8mb4(table_name, col_name, collation = 'utf8mb4_unicode_ci')
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
