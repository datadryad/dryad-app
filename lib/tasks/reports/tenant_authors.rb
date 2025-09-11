# :nocov:
require 'csv'

module Tasks
  module Reports
    class TenantAuthors
      attr_reader :tenant

      def initialize(tenant)
        @tenant = tenant
      end

      def call
        CSV.open(File.join(Rails.root.join('reports'), "#{tenant.id}-authors-report-#{Time.now.strftime('%Y-%m-%d')}.csv"), 'wb') do |csv|
          csv << header

          items_query.each do |resource|
            resource.authors.each do |author|
              identifier = resource.identifier
              csv << [
                author_email(author), author.author_full_name, resource&.title,
                identifier.identifier, resource.tenant&.long_name, metrics(identifier.counter_stat),
                identifier.publication_date,
                identifier.process_date.processing,
                resource.curation_activities.order(:created_at).last.status,
                author.affiliations.map(&:long_name).join(', '),
                resource.journal&.title,
                resource.contributors.where(contributor_type: 'funder').map(&:contributor_name).join(', ')
              ]
            end
          end
          true
        end
      end

      private

      def ror_ids
        tenant.ror_ids
      end

      def header
        [
          'Email', 'Author name', 'Dataset', 'DOI', 'Tenant', 'Metrics', 'Date first published', 'Date first submitted',
          'Status', 'Affiliations', 'Journal', 'Funders'
        ]
      end

      def items_query
        StashEngine::Resource.latest_per_dataset.joins(tenant: :ror_orgs)
          .includes(
            { authors: :affiliations },
            :tenant,
            :journal,
            :contributors,
            :curation_activities,
            identifier: %i[process_date counter_stat]
          ).where(stash_engine_ror_orgs: { ror_id: ror_ids })
      end

      def metrics(counter_stat)
        c = counter_stat.unique_investigation_count
        r = counter_stat.unique_request_count
        views = c.blank? || c < r ? (r || 0) : c
        "#{views} views, #{r || 0} downloads, #{counter_stat.citation_count || 0} citations"
      end

      def author_email(author)
        author.author_email || StashEngine::User.where(orcid: author.author_orcid)&.first&.email
      end
    end
  end
end
# :nocov:
