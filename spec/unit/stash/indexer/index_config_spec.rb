require 'spec_helper'

module Stash
  module Indexer
    describe IndexConfig do

      describe '#build_from' do
        it 'reads a valid Solr config' do
          url = 'http://example.org'
          proxy = 'http://proxy.example.org'
          hash = { adapter: 'Solr', url: url, proxy: proxy }

          config = IndexConfig.build_from(hash)
          expect(config).to be_a(Solr::SolrIndexConfig)
          expect(config.uri).to eq(URI(url))
          expect(config.proxy_uri).to eq(URI(proxy))
        end
      end

      describe '#create_indexer' do
        it 'is abstract' do
          config = IndexConfig.new(url: URI('http://example.org/index'))
          metadata_mapper = instance_double(MetadataMapper)
          expect { config.create_indexer(metadata_mapper: metadata_mapper) }.to raise_error(NoMethodError)
        end

        it 'creates a Solr indexer' do
          url = 'http://example.org'
          proxy = 'http://proxy.example.org'
          hash = { adapter: 'Solr', url: url, proxy: proxy }

          config = IndexConfig.build_from(hash)

          metadata_mapper = instance_double(MetadataMapper)

          indexer = config.create_indexer(metadata_mapper)
          expect(indexer).to be_a(Solr::SolrIndexer)
        end
      end

      describe '#description' do
        it 'is abstract' do
          config = IndexConfig.new(url: 'http://example.org/')
          expect { config.description }.to raise_error(NoMethodError)
        end
      end

    end
  end
end
