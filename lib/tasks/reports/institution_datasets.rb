require 'byebug'
require 'csv'

module Tasks
  module Reports
    module InstitutionDatasets
      # rubocop:disable Metrics/MethodLength
      def self.datasets_by_name(name:)
        sanitized_ver = ActiveRecord::Base.sanitize_sql("%#{name}%")
        query = <<~SQL.strip
          SELECT DISTINCT * FROM stash_engine_identifiers ids1
          JOIN (
            (SELECT ids.id
            FROM dcs_affiliations affil
            JOIN dcs_affiliations_authors affil_auth
            ON affil.id = affil_auth.`affiliation_id`
            JOIN stash_engine_authors auth
            ON affil_auth.`author_id` = auth.id
            JOIN stash_engine_resources res
            ON auth.`resource_id` = res.id
            JOIN `stash_engine_identifiers` ids
            ON res.`identifier_id` = ids.id
            WHERE affil.long_name LIKE "#{sanitized_ver}")
            UNION
            (SELECT ids.id
            FROM dcs_contributors contrib
            JOIN stash_engine_resources res
            ON contrib.`resource_id` = res.id
            JOIN `stash_engine_identifiers` ids
            ON res.`identifier_id` = ids.id
            WHERE contrib.`contributor_name` LIKE "#{sanitized_ver}")) ids2
          ON ids1.id = ids2.id
        SQL

        idents = StashEngine::Identifier.find_by_sql(query)

        CSV.open(File.join(Rails.root, "#{name}-#{Time.now.strftime('%Y-%m-%d')}.tsv"), 'wb',
                 col_sep: "\t", row_sep: "\n") do |csv|
          csv << %w[doi pub_state title author_affiliations contributor_affiliations]
          idents.each_with_index do |ident, idx|
            res = ident.latest_resource
            # get matching author affiliations
            auth_affil = StashDatacite::Affiliation.joins(:authors)
              .where(stash_engine_authors: { resource_id: res.id })
              .where('long_name LIKE ?', "%#{name}%")
              .select(:long_name)
            matched_affiliations = auth_affil.map(&:long_name).uniq

            # get matching contributor affiliations
            contrib_affil = StashDatacite::Contributor.where(resource_id: res.id).where('contributor_name LIKE ?',
                                                                                        "%#{name}%").select(:contributor_name)
            matched_contrib_affil = contrib_affil.map(&:contributor_name).uniq

            csv << [ident.identifier, ident.pub_state, res.title, matched_affiliations.join('|'), matched_contrib_affil.join('|')]
            puts "Processed #{idx + 1}" if (idx + 1) % 50 == 0
          end
        end
      end
      # rubocop:enable Metrics/MethodLength
    end
  end
end
