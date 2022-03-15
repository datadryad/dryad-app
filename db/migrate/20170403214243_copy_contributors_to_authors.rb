class CopyContributorsToAuthors < ActiveRecord::Migration[4.2]
  def change
    execute <<-SQL
      INSERT INTO stash_engine_authors (
                    id,
                    resource_id,
                    author_first_name,
                    author_last_name,
                    author_email,
                    author_orcid,
                    created_at,
                    updated_at
                  )
           SELECT creators.id,
                  creators.resource_id,
                  creators.creator_first_name,
                  creators.creator_last_name,
                  emails.email,
                  orcids.orcid,
                  creators.created_at,
                  NOW()
             FROM dcs_creators creators
                  LEFT OUTER JOIN (SELECT name_idents.id,
                                          TRIM(LEADING 'mailto:'
                                                  FROM name_idents.name_identifier)
                                            AS email
                                     FROM dcs_name_identifiers name_idents
                                    WHERE name_idents.name_identifier_scheme = 'email')
                               AS emails
                               ON emails.id = creators.name_identifier_id
                  LEFT OUTER JOIN (SELECT name_idents.id,
                                          name_idents.name_identifier
                                       AS orcid
                                     FROM dcs_name_identifiers name_idents
                                    WHERE name_idents.name_identifier_scheme = 'ORCID')
                               AS orcids
                               ON orcids.id = creators.name_identifier_id
      ;
    SQL
  end
end
