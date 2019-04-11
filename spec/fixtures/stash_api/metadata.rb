require 'faker'
require 'json'

module Fixtures
  module StashApi
    class Metadata

      def initialize
        @metadata = ActiveSupport::HashWithIndifferentAccess.new
      end

      def hash
        @metadata.with_indifferent_access
      end

      def json
        @metadata.to_json
      end

      def make_minimal
        add_title
        add_abstract
        add_author
      end

      def add_title
        @metadata.merge!(title: Faker::Book.title)
      end

      def add_author
        @metadata[:authors] = [] unless @metadata['authors']
        @metadata[:authors].push(
          { "firstName": Faker::Name.first_name,
            "lastName": Faker::Name.last_name,
            email: Faker::Internet.email,
            affiliation: Faker::University.name }.with_indifferent_access
        )
      end

      def add_abstract
        @metadata.merge!(abstract: Faker::Lorem.paragraph)
      end

    end
  end
end
