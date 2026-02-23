# :nocov:
require 'byebug'
require 'csv'

module Tasks
  module Reports
    class PublishedAuthorReport
      def call
        CSV.open(File.join(Rails.root.join('reports'), "published_authors_report-#{Time.now.strftime('%Y-%m-%d')}.csv"), 'wb') do |csv|
          csv << ['First name', 'Last name', 'Email', 'ORCID']
          author_ids = StashEngine::Author
            .where.not(author_email: [nil, ''])
            .where.not(author_orcid: [nil, ''])
            .select('max(id) as id')
            .group(:author_email, :author_orcid)

          StashEngine::Author.where(id: author_ids)
            .each do |author|

            csv << [author.author_first_name, author.author_last_name, author.author_email, author.author_orcid]
          end
        end

        true
      end
    end
  end
end
# :nocov:
