class CopyOrcidToUsers < ActiveRecord::Migration[4.2]
  # rubocop:disable Metrics/MethodLength
  def change
    update_stmt = <<-SQL
          UPDATE stash_engine_users u
      INNER JOIN (
                      SELECT r.user_id AS user_id,
                             a.id AS author_id,
                             a.author_orcid AS author_orcid,
                             a.author_first_name AS author_first_name,
                             a.author_last_name AS author_last_name
                        FROM stash_engine_resources r,
                             stash_engine_authors a
                       WHERE a.resource_id = r.id
                         AND a.author_orcid IS NOT NULL
                    GROUP BY author_id
                  ) AS o
               ON u.id         = o.user_id
              AND u.first_name = o.author_first_name
              AND u.last_name  = o.author_last_name
              SET u.orcid = o.author_orcid;
    SQL

    # indentation/newlines are good for code, bad for log output (which ignores newlines)
    execute update_stmt.squish

    # Now we've set the ORCiDs of all users whose names exactly match
    # at least one of their ORCiD-having authors, but we'll still have
    # some ORCiDs we can't match up:

    unmatched = connection.select_all <<-SQL
        SELECT DISTINCT
               u.id as user_id,
               u.first_name,
               u.last_name,
               a.author_orcid,
               a.author_first_name,
               a.author_last_name
          FROM stash_engine_users u,
               stash_engine_resources r,
               stash_engine_authors a
         WHERE u.orcid IS NULL
           AND u.id = r.user_id
           AND a.resource_id = r.id
           AND a.author_orcid IS NOT NULL
      ORDER BY user_id, author_orcid
    SQL
    return if unmatched.empty?

    say 'WARNING: Possible ORCiDs were found for the following users, but could not be definitively assigned due to name mismatch:'
    say(unmatched.columns.join("\t"), true)
    unmatched.each do |row|
      say(row.values.join("\t"), true)
    end
  end
  # rubocop:enable Metrics/MethodLength
end
