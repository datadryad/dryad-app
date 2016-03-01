module Stash
  module Indexer
    module Solr
      class SolrIndexer < Indexer
        # Creates a new `SolrIndexer`
        # @param config [SolrIndexConfig] the configuration for this indexer.
        def initialize(config:)
          @config = config
        end

        def index(harvested_records)
          solr = RSolr.connect(@config.opts)
          solr.add harvested_records.to_a
          solr.commit
        end
      end
    end
  end
end
