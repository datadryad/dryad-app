module Stash
  module Indexer
    class Indexer

      attr_reader :metadata_mapper

      # Creates a new indexer
      # @param metadata_mapper [MetadataMapper] the metadata mapper to convert
      #   harvested documents to indexable documents
      def initialize(metadata_mapper:)
        @metadata_mapper = metadata_mapper
      end

      # Indexes the specified records.
      # @param harvested_records [Enumerator::Lazy<HarvestedRecord>] The records to index.
      # @yield [IndexResult] the result of the index operation for each record
      def index(harvested_records) # rubocop:disable Lint/UnusedMethodArgument
        raise NoMethodError, "#{self.class} should override #index to index records, but it doesn't"
      end
    end
  end
end
