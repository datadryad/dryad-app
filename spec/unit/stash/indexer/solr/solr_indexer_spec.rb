require 'spec_helper'

require 'rsolr'

module Stash
  module Indexer
    module Solr
      describe SolrIndexer do
        it 'is an Indexer' do
          config = instance_double(SolrIndexConfig)
          metadata_mapper = instance_double(MetadataMapper)
          expect(SolrIndexer.new(metadata_mapper: metadata_mapper, config: config)).to be_an(Indexer)
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
            @metadata_mapper = instance_double(MetadataMapper)
            @indexer = SolrIndexer.new(metadata_mapper: @metadata_mapper, config: @config)

            @solr = instance_double(RSolr::Client)
            allow(@solr).to receive(:add)
            allow(@solr).to receive(:commit)

            expect(RSolr::Client).to receive(:new) do |_connection, options|
              @rsolr_options = options
              @solr
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

          it 'transforms and indexes records using the specified metadata mapper' do
            harvested_record_array = Array.new(3) { |_i| instance_double(Stash::Harvester::HarvestedRecord) }
            harvested_record_array.each_with_index do |r, i|
              content = instance_double(Stash::Wrapper::StashWrapper)
              expect(r).to receive(:deleted?) { false }
              expect(r).to receive(:content) { content }
              index_doc = { id: i.to_s }
              expect(@metadata_mapper).to receive(:to_index_document).with(content) { index_doc }
              expect(@solr).to receive(:add).with(index_doc)
            end
            expect(@solr).to receive(:commit)
            @indexer.index(harvested_record_array.lazy)
          end

          it 'deletes deleted records' do
            harvested_record_array = Array.new(3) { |_i| instance_double(Stash::Harvester::HarvestedRecord) }
            harvested_record_array.each_with_index do |r, i|
              if i.odd?
                expect(r).to receive(:deleted?) { true }
                identifier = i.to_s
                expect(r).to receive(:identifier) { identifier }
                expect(@solr).to receive(:delete_by_id).with(identifier)
              else
                content = instance_double(Stash::Wrapper::StashWrapper)
                expect(r).to receive(:deleted?) { false }
                expect(r).to receive(:content) { content }
                index_doc = { id: i.to_s }
                expect(@metadata_mapper).to receive(:to_index_document).with(content) { index_doc }
              end
            end
            expect(@solr).to receive(:commit)
            @indexer.index(harvested_record_array.lazy)
          end

          it 'handles partial add failures' do
            harvested_record_array = Array.new(3) { |_i| instance_double(Stash::Harvester::HarvestedRecord) }
            harvested_record_array.each_with_index do |r, i|
              content = instance_double(Stash::Wrapper::StashWrapper)
              expect(r).to receive(:deleted?) { false }
              expect(r).to receive(:content) { content }
              id = i.to_s
              allow(r).to receive(:identifier) { id }
              index_doc = { id: id }
              expect(@metadata_mapper).to receive(:to_index_document).with(content) { index_doc }
              if i == 2
                request = instance_double(Net::HTTP::Get)
                response = instance_double(Net::HTTPResponse)
                error = RSolr::Error::InvalidResponse.new(request, response)
                error.define_singleton_method(:to_s) { '(mock InvalidResponse)' }
                expect(@solr).to receive(:add).with(index_doc).and_raise(error)
              else
                expect(@solr).to receive(:add).with(index_doc)
              end
            end
            expect(@solr).to receive(:commit)
            @indexer.index(harvested_record_array.lazy)
          end

          it 'handles partial delete failures' do
            harvested_record_array = Array.new(3) { |_i| instance_double(Stash::Harvester::HarvestedRecord) }
            harvested_record_array.each_with_index do |r, i|
              expect(r).to receive(:deleted?) { true }
              id = i.to_s
              allow(r).to receive(:identifier) { id }
              if i == 2
                request = instance_double(Net::HTTP::Get)
                response = instance_double(Net::HTTPResponse)
                error = RSolr::Error::InvalidResponse.new(request, response)
                error.define_singleton_method(:to_s) { '(mock InvalidResponse)' }
                expect(@solr).to receive(:delete_by_id).with(id).and_raise(error)
              else
                expect(@solr).to receive(:delete_by_id).with(id)
              end
            end
            expect(@solr).to receive(:commit)
            @indexer.index(harvested_record_array.lazy)
          end

          it 'returns some useful per-record status'

          it 'respects the configured batch size'

        end
      end
    end
  end
end
