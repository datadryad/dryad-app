module Stash
  module Indexer
    module RorIndexer

      def index_mappings
        {
          uuid: id.to_s,
          id: id,
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

      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        def reindex_all
          all.each(&:reindex)
        end

        def search(query, fq: [], operation: 'OR')
          solr = RSolr.connect(url: APP_CONFIG.ror_solr_url)
          query = '*:*' if query.blank?

          filters = { q: query }
          filters.merge!({ fq: fq.join(" #{operation} ") }) if fq.present?

          solr.get('select', params: filters)
        end
      end
    end
  end
end
