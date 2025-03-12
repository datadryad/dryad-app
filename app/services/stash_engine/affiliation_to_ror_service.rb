module StashEngine
  class AffiliationToRorService

    # attr_reader :data_file, :resource
    FILE_NAME = "affiliations_to_ror_export_#{Date.today.strftime('%Y-%m-%d')}.csv".freeze

    def initialize()
      # credentials = ::Aws::Credentials.new(APP_CONFIG[:s3][:key], APP_CONFIG[:s3][:secret])
      # @client     = Aws::Lambda::Client.new(region: APP_CONFIG[:s3][:region], credentials: credentials)
      # @data_file  = data_file
      # @resource   = resource
    end

    def info_list
      published_affiliation_ids_subquery = StashEngine::CurationActivity.where(status: ['published', 'embargoed']).joins(resource: {authors: :affiliations}).select('dcs_affiliations.id').distinct.to_sql
      affiliations_query = "select
                      long_name,
                      COUNT(1) AS affiliations_count,
                      (select count(1) from dcs_affiliations_authors where dcs_affiliations_authors.affiliation_id = dcs_affiliations.id) AS authors_count
                    from dcs_affiliations
                    where ror_id is NULL AND id IN (#{published_affiliation_ids_subquery})
                    group by long_name"
      CSV.open(File.join(Rails.root, 'reports', "affiliations_report_#{Time.now.strftime('%Y-%m-%d')}.csv"), 'w') do |csv|
        csv << ['Affiliation name', 'Affiliation count', 'Authors count']
        ActiveRecord::Base.connection.execute(affiliations_query).each do |affiliation|
          csv << affiliation
        end
      end
    end

    def export

      CSV.open(FILE_NAME, 'w') do |csv|
        csv << columns_header
        StashDatacite::Affiliation.joins(:authors)
          .where(ror_id: nil)
          .joins(latest_resource: :resource_publication)
          .where.not(resource_publication: { publication_issn: nil })
          .where.not(id: StashEngine::Resource
                           .joins(:related_identifiers)
                           .where({
                                    "#{StashDatacite::RelatedIdentifier.table_name}.related_identifier_type": 'doi',
                                    "#{StashDatacite::RelatedIdentifier.table_name}.work_type": 'primary_article'
                                  })
                           .pluck(:identifier_id)
          ).find_each do |af|

          csv << [af.long_name, af.short_name, af.abbreviation, nil, nil, af.publication_issn, af.resource_publication.publication_issn]
        end
      end
    end

    private

    def columns_header
      ['Organization name*', 'Names in other languages', 'Name variations', 'Acronym', 'Organization website*', 'Link to publications associated with this organization*', 'Wikipedia page', 'Wikidata ID', 'ISNI ID', 'GRID ID', 'Crossref Funder ID', 'Type of organization*', 'Year established', 'Parent org in ROR', 'Child org in ROR', 'Related org in ROR', 'City where org is located*', 'Country where org is located*', 'Requestor comments']
    end
  end
end
