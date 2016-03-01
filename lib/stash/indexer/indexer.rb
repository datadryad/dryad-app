module Stash
  module Indexer
    class Indexer
      # Indexes the specified records.
      # @param _harvested_records [Enumerator::Lazy<HarvestedRecord>] The records to index.
      def index(_harvested_records)
        raise NoMethodError, "#{self.class} should override #index to index records, but it doesn't"
      end
    end
  end
end
