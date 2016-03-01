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
          before(:each) do
            @url = 'http://example.org/'
            @proxy = 'http://proxy.example.org'
            @elvis = 'presley'
            @config = SolrIndexConfig.new(
              url: @url,
              proxy: @proxy,
              elvis: @elvis
            )
            @indexer = SolrIndexer.new(config: @config)

            @rsolr_client = instance_double(RSolr::Client)
            allow(@rsolr_client).to receive(:add)
            allow(@rsolr_client).to receive(:commit)

            expect(RSolr::Client).to receive(:new) do |_connection, options|
              @rsolr_options = options
              @rsolr_client
            end
          end

          it 'uses the correct URL' do
            @indexer.index([].lazy)
            expect(@rsolr_options[:url]).to eq(@url)
          end

          it 'uses the correct proxy URL' do
            @indexer.index([].lazy)
            expect(@rsolr_options[:proxy]).to eq(@proxy)
          end

          it 'passes other options to the Solr client' do
            @indexer.index([].lazy)
            expect(@rsolr_options[:elvis]).to eq(@elvis)
          end

          it 'indexes records' do
            records = [{ id: '10.1000/12345' }, { id: '10.1000/67890' }]
            expect(@rsolr_client).to receive(:add).with(records)
            @indexer.index(records.lazy)
          end

          it 'respects the configured batch size'
          it 'is lazy with regard to failures'
          it 'commits partial adds'
          it 'returns some useful status'
        end
      end
    end
  end
end
