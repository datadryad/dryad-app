require 'faker'
require 'json'

# This fixture generates metadata for the API in the format produced by Editorial Manager.
# It should only be used for testing Editorial Manager functionality, not regular Dryad API calls.
module Fixtures
  module StashApi
    class EmMetadata

      def initialize
        @metadata = ActiveSupport::HashWithIndifferentAccess.new
      end

      def hash
        @metadata.with_indifferent_access
      end

      def json
        @metadata.to_json
      end

      def make_deposit_metadata
        add_title
        add_journal_name
        add_author
      end

      def make_submission_metadata
        add_title
        add_journal_name
        add_embargo_info
        add_article
        add_author
      end

      def add_title
        title = Faker::Book.title
        dd = ActiveSupport::HashWithIndifferentAccess.new
        dd.merge!(deposit_description: title)
        @metadata[:deposit_data] = dd
      end

      def add_journal_name
        @metadata.merge!(journal_full_title: Faker::Book.title)
      end

      def add_author
        create_key_and_array(key: :authors)
        @metadata[:authors].push(
          { first_name: Faker::Name.first_name,
            last_name: Faker::Name.last_name,
            email: Faker::Internet.email,
            orcid: "#{Faker::Number.number(digits: 4)}-#{Faker::Number.number(digits: 4)}-" \
                   "#{Faker::Number.number(digits: 4)}-#{Faker::Number.number(digits: 4)}",
            institution: Faker::University.name }.with_indifferent_access
        )
      end

      def create_key_and_array(key:)
        @metadata[key] = [] unless @metadata[key]
      end

      def add_embargo_info
        @metadata.merge!(embargo_type: 'Publication')
        @metadata.merge!(embargo_days: Faker::Number.number(digits: 2))
      end

      def add_article
        article = ActiveSupport::HashWithIndifferentAccess.new
        article.merge!(article_doi: "10.#{Faker::Number.number(digits: 4)}/#{Faker::Number.number(digits: 10)}")
        article.merge!(article_title: Faker::TvShows::SiliconValley.quote)
        article.merge!(abstract: Faker::Lorem.paragraph)
        article.merge!(final_disposition: 'ACCEPT')
        article.merge!(keywords: [Faker::Cosmere.aon, Faker::Cosmere.metal, Faker::Cosmere.spren])
        article.merge!(funding_information: [{
                         funder: Faker::Company.name,
                         funder_id: Faker::Pid.doi,
                         award_number: Faker::Alphanumeric.alphanumeric(number: 8, min_alpha: 2, min_numeric: 4),
                         grant_recipient: Faker::Alphanumeric.alphanumeric(number: 8, min_alpha: 2, min_numeric: 4)
                       }])

        @metadata[:article] = article
      end

    end
  end
end
