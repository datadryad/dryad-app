require 'byebug'
require 'csv'

module Tasks
  module Reports
    module RorAuthorDatasets
      # rubocop:disable Metrics/MethodLength
      def self.submitted_report(tenant:)
        # get all the ROR tenant values as ('val1', 'val2', 'val3') type string for using in IN query in SQL
        rors = StashEngine::Tenant.find(tenant).ror_ids
        ror_in_string = "('#{rors.join("', '")}')"

        # monster report query transported from running it manually in MySQL client, with RORs substituted
        query = <<~SQL.strip
          SELECT
            se_id3.identifier, se_res3.title, se_auth3.author_first_name, se_auth3.author_last_name, dcs_affil3.long_name,
            se_res3.publication_date, se_id3.pub_state,
            (stash_engine_counter_stats.unique_investigation_count - stash_engine_counter_stats.unique_request_count) as unique_views,
            stash_engine_counter_stats.unique_request_count as unique_downloads
          FROM
            /* get only the latest one */
            (SELECT unique_ids.identifier_id, max(res2.id) last_submitted_resource FROM
              /* only get distinct identifiers from all the ror_ids working back through zillions of joined tables */
              (SELECT DISTINCT
                se_id.id as identifier_id
    	        FROM dcs_affiliations affil JOIN dcs_affiliations_authors affil_auth
    	          ON affil.id = affil_auth.`affiliation_id`
    	        JOIN stash_engine_authors auth
    	          ON affil_auth.`author_id` = auth.`id`
    	        JOIN stash_engine_resources res
    	          ON auth.`resource_id` = res.id
    	        JOIN stash_engine_identifiers se_id
    	          ON se_id.id = res.identifier_id
    	        JOIN stash_engine_resource_states se_rs
    	          ON res.id = se_rs.resource_id
    	        WHERE
                affil.ror_id IN #{ror_in_string}
    	          AND se_rs.resource_state = 'submitted') as unique_ids
            JOIN stash_engine_resources res2
              ON unique_ids.identifier_id = res2.identifier_id
            GROUP BY unique_ids.identifier_id) as ident_and_res#{'	'}
          JOIN stash_engine_identifiers se_id3
            ON se_id3.id = ident_and_res.identifier_id
          JOIN stash_engine_resources se_res3
            ON se_res3.id = ident_and_res.last_submitted_resource
          JOIN stash_engine_authors se_auth3
            ON se_res3.id = se_auth3.`resource_id`
          JOIN dcs_affiliations_authors dcs_affils_authors3
            ON se_auth3.`id` = dcs_affils_authors3.`author_id`
          JOIN dcs_affiliations dcs_affil3
            ON dcs_affils_authors3.`affiliation_id` = dcs_affil3.`id`
          LEFT JOIN stash_engine_counter_stats
            ON se_id3.id = stash_engine_counter_stats.`identifier_id`
          WHERE dcs_affil3.ror_id IN #{ror_in_string}
          ORDER BY se_res3.publication_date, se_id3.identifier, se_res3.title;
        SQL

        result = ActiveRecord::Base.connection.exec_query(query)

        CSV.open(File.join(Rails.root, "#{tenant}-#{Time.now.strftime('%Y-%m-%d')}.tsv"), 'wb',
                 col_sep: "\t", row_sep: "\n") do |csv|
          csv << result.columns
          result.rows.each do |row|
            csv << row
          end
        end
      end
      # rubocop:enable Metrics/MethodLength
    end
  end
end
