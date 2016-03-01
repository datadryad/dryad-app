require 'spec_helper'

module Stash
  module Indexer
    module Solr
      describe SolrIndexer do
        it 'is an Indexer' do
          config = instance_double(SolrIndexConfig)
          expect(SolrIndexer.new(config: config)).to be_an(Indexer)
        end
        describe '#index' do
          it 'uses the correct URL'
          it 'uses the correct proxy URL'
          it 'passes other options to the Solr client'
          it 'indexes records'
          it 'respects the configured batch size'
          it 'is lazy with regard to failures'
          it 'commits partial adds'
          it 'returns some useful status'
        end
      end
    end
  end
end
