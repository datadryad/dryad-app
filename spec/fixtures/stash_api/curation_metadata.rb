require 'faker'
require 'json'
module Fixtures
  module StashApi
    class CurationMetadata

      def initialize
        @curation_metadata = ActiveSupport::HashWithIndifferentAccess.new
        @curation_metadata[:status] = 'published'
        add_note
      end

      def hash
        @curation_metadata.with_indifferent_access
      end

      def json
        @curation_metadata.to_json
      end

      def add_note
        @curation_metadata.merge!(note: Faker::Lorem.paragraph)
      end

    end
  end
end
