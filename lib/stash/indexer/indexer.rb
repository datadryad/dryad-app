module Stash
  module Indexer
    class Indexer
      # Indexes the specified records.
      # @param harvested_records [Enumerator::Lazy<HarvestedRecord>] The records to index.
      def index(harvested_records) # rubocop:disable Lint/UnusedMethodArgument
        raise NoMethodError, "#{self.class} should override #index to index records, but it doesn't"
      end
    end
  end
end
