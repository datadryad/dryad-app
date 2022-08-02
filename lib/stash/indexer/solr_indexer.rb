require 'rsolr'

module Stash
  module Indexer
    class SolrIndexer

      attr_reader :solr

      ADD_ATTRIBUTES = { commitWithin: 10 }.freeze # means it won't take forever to commit

      def initialize(solr_url:)
        # rsolr gives lots of other config options, but this is probably all we need for now
        @solr = RSolr.connect(url: solr_url, retry_503: 3, retry_after_limit: 1, timeout: 20)
      end

      def index_document(solr_hash:)
        result = @solr.add(solr_hash, add_attributes: ADD_ATTRIBUTES)
        return true if result['responseHeader']['status'] == 0

        false
      rescue StandardError => e
        Rails.logger.error("Error adding record with hash #{solr_hash || 'nil'}: #{e}")
        Rails.logger.debug(e.full_message) if e.backtrace
        false
      end

      def delete_document(doi:)
        result = @solr.delete_by_id(doi)
        @solr.commit
        return true if result['responseHeader']['status'] == 0

        false
      rescue StandardError => e
        Rails.logger.error("Error deleting record with identifier #{doi || 'nil'}: #{e}")
        Rails.logger.debug(e.full_message) if e.backtrace
        false
      end

    end
  end
end
