require 'spec_helper'

module Stash
  module Harvester
    describe IndexConfig do
      describe '#for_adapter' do
        it 'understands Solr' do
          expect(IndexConfig.for_adapter('Solr')).to be(Solr::SolrIndexConfig)
        end

        it 'fails for bad adapters' do
          bad_adapter = 'Elvis'
          expect { IndexConfig.for_adapter(bad_adapter) }.to raise_error do |e|
            expect(e).to be_an(ArgumentError)
            expect(e.message).to include(bad_adapter)
          end
        end

        it 'works for new adapters' do
          module Foo
            class FooIndexConfig < IndexConfig
            end
          end
          expect(IndexConfig.for_adapter('Foo')).to be(Foo::FooIndexConfig)
        end
      end

      describe '#from_hash' do
        it 'reads a valid Solr config' do
          url = 'http://example.org'
          proxy = 'http://proxy.example.org'
          hash = { adapter: 'Solr', url: url, proxy: proxy }

          config = IndexConfig.from_hash(hash)
          expect(config).to be_a(Solr::SolrIndexConfig)
          expect(config.uri).to eq(URI(url))
          expect(config.proxy_uri).to eq(URI(proxy))
        end
      end
    end
  end
end
