class DropOrcidIdFromDcsCreators < ActiveRecord::Migration[4.2]
  def change
    # Create missing name identifier records
    execute <<-SQL
      INSERT INTO dcs_name_identifiers
                  (name_identifier, name_identifier_scheme, scheme_URI, created_at, updated_at)
           SELECT creators.orcid_id, 'ORCID', 'http://orcid.org', NOW(), NOW()
             FROM dcs_creators AS creators
            WHERE creators.orcid_id IS NOT NULL
              AND creators.orcid_id NOT IN
                  (SELECT name_identifier
                     FROM dcs_name_identifiers);
    SQL

    # Make sure any existing ORCID name identifiers have the correct scheme and scheme URI
    execute <<-SQL
      UPDATE dcs_name_identifiers
         SET name_identifier_scheme = 'ORCID',
             scheme_URI = 'http://orcid.org'
       WHERE name_identifier IN
             (SELECT orcid_id FROM dcs_creators);
    SQL

    # Link creators to name identifiers
    execute <<-SQL
      UPDATE dcs_creators
         SET name_identifier_id =
             (SELECT id
                FROM dcs_name_identifiers
               WHERE dcs_name_identifiers.name_identifier = dcs_creators.orcid_id);
    SQL

    # Remove old orcid_id column
    remove_column :dcs_creators, :orcid_id
  end

end
