require 'stash/indexer/index_config'

module Stash
  module Indexer
    # The {IndexConfig} equivalent of `/dev/null`.
    class NullIndexConfig < IndexConfig
      adapter 'none'

      def initialize(*_args)
        @uri = nil
      end

      # Creates an anonymous indexer that yields a successful {IndexResult}
      # for each harvested record.
      # @param metadata_mapper [MetadataMapper] the metadata mapper (unused)
      # @return [Indexer] a no-op indexer that always succeeds
      def create_indexer(metadata_mapper:)
        indexer = Indexer.new(metadata_mapper: metadata_mapper)
        def indexer.index(harvested_records)
          harvested_records.each do |r|
            yield IndexResult.success(r) if block_given?
          end
        end
        indexer
      end

      def description
        'none'
      end
    end
  end
end
