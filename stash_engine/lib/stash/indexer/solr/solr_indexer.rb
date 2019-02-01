module Stash
  module Indexer
    module Solr
      class SolrIndexer

        attr_reader :config, :metadata_mapper

        # Creates a new `SolrIndexer`
        # @param metadata_mapper [MetadataMapper] the metadata mapper to convert
        #   harvested documents to indexable documents
        # @param config [SolrIndexConfig] the configuration for this indexer.
        def initialize(metadata_mapper:, config:)
          @metadata_mapper = metadata_mapper
          @config = config
        end

        # Indexes the specified records, deleting any deleted records.
        # @param harvested_records [Enumerator::Lazy<HarvestedRecord>] The records to index.
        # @yield [IndexResult] the result of the index operation for each record
        def index(harvested_records)
          solr = RSolr.connect(@config.opts)
          # TODO: Performance-test this -- is it OK to perform x-thousand add operations?
          harvested_records.each do |r|
            begin
              r.deleted? ? delete_record(r, solr) : index_record(r, solr)
              yield IndexResult.success(r) if block_given?
            rescue StandardError => e
              yield IndexResult.failure(r, [e]) if block_given?
            end
          end
          solr.commit
        end

        private

        def log
          Stash::Indexer.log
        end

        def index_record(record, solr)
          wrapped_metadata = record.as_wrapper
          index_document = metadata_mapper.to_index_document(wrapped_metadata)
          solr.add index_document
        rescue StandardError => e
          identifier = record.identifier if record
          log.error("Error adding record with identifier #{identifier || 'nil'}: #{e}")
          log.debug(e.backtrace.join("\n")) if e.backtrace
          raise
        end

        def delete_record(record, solr)
          solr.delete_by_id record.identifier
        rescue StandardError => e
          identifier = record.identifier if record
          log.error("Error deleting record with identifier #{identifier || 'nil'}: #{e}")
          log.debug(e.backtrace.join("\n")) if e.backtrace
          raise
        end
      end
    end
  end
end
