module Stash
  module Indexer
    module RorIndexer
      extend ActiveSupport::Concern

      included do
        after_commit :reindex
        after_destroy_commit :remove_from_solr_index

        class << self
          def reindex_all
            all.each(&:reindex)
          end

          def search(query, fq: [], operation: 'OR', limit: 100, fl: nil)
            solr = RSolr.connect(url: APP_CONFIG.ror_solr_url)

            filters = {}
            filters = { q: query } if query.present?
            filters.merge!({ fq: fq.join(" #{operation} ") }) if fq.present?
            filters.merge!({ fl: fl }) if fl.present?

            solr.get('select', params: filters, rows: limit, debugQuery: true)
          end
        end
      end

      def index_mappings
        {
          id: id.to_s,
          name: name,
          ror_id: ror_id,
          aliases: aliases,
          country: country,
          home_page: home_page,
          acronyms: acronyms,
          isni_ids: isni_ids
        }
      end

      def submit_to_solr
        solr_indexer = Stash::Indexer::SolrIndexer.new(solr_url: APP_CONFIG.ror_solr_url)
        solr_indexer.index_document(solr_hash: index_mappings)
      end

      def reindex
        submit_to_solr
      end

      def remove_from_solr_index
        solr_indexer = Stash::Indexer::SolrIndexer.new(solr_url: APP_CONFIG.ror_solr_url)
        solr_indexer.destroy_document(id: id.to_s)
      end
    end
  end
end
