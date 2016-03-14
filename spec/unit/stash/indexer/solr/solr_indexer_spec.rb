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
            records = Array.new(3) { |_i| instance_double(Stash::Harvester::HarvestedRecord) }
            records.each_with_index do |r, i|
              content = instance_double(Stash::Wrapper::StashWrapper)
              expect(r).to receive(:deleted?) { false }
              expect(r).to receive(:content) { content }
              index_doc = { id: i.to_s }
              expect(@metadata_mapper).to receive(:to_index_document).with(content) { index_doc }
              expect(@solr).to receive(:add).with(index_doc)
            end
            expect(@solr).to receive(:commit)
            @indexer.index(records.lazy)
          end

          it 'deletes deleted records' do
            records = Array.new(3) { |_i| instance_double(Stash::Harvester::HarvestedRecord) }
            records.each_with_index do |r, i|
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
            @indexer.index(records.lazy)
          end

          it 'handles partial add failures' do
            records = Array.new(3) { |_i| instance_double(Stash::Harvester::HarvestedRecord) }
            records.each_with_index do |r, i|
              content = instance_double(Stash::Wrapper::StashWrapper)
              expect(r).to receive(:deleted?) { false }
              expect(r).to receive(:content) { content }
              id = i.to_s
              allow(r).to receive(:identifier) { id }
              index_doc = { id: id }
              expect(@metadata_mapper).to receive(:to_index_document).with(content) { index_doc }
              if i == 2
                error = RSolr::Error::InvalidResponse.new(instance_double(Net::HTTP::Get), instance_double(Net::HTTPResponse))
                error.define_singleton_method(:to_s) { '(mock InvalidResponse)' }
                expect(@solr).to receive(:add).with(index_doc).and_raise(error)
              else
                expect(@solr).to receive(:add).with(index_doc)
              end
            end
            expect(@solr).to receive(:commit)
            @indexer.index(records.lazy)
          end

          it 'handles partial delete failures' do
            records = Array.new(3) { |_i| instance_double(Stash::Harvester::HarvestedRecord) }
            records.each_with_index do |r, i|
              expect(r).to receive(:deleted?) { true }
              id = i.to_s
              allow(r).to receive(:identifier) { id }
              if i == 2
                error = RSolr::Error::InvalidResponse.new(instance_double(Net::HTTP::Get), instance_double(Net::HTTPResponse))
                error.define_singleton_method(:to_s) { '(mock InvalidResponse)' }
                expect(@solr).to receive(:delete_by_id).with(id).and_raise(error)
              else
                expect(@solr).to receive(:delete_by_id).with(id)
              end
            end
            expect(@solr).to receive(:commit)
            @indexer.index(records.lazy)
          end

          it 'yields per-record status' do
            records = Array.new(4) do |i|
              record = instance_double(Stash::Harvester::HarvestedRecord)
              allow(record).to receive(:identifier) { "10.0/#{i}" }
              record
            end
            [0, 1].each do |i|
              expect(records[i]).to receive(:deleted?) { true }
            end
            [2, 3].each do |i|
              r = records[i]
              expect(r).to receive(:deleted?) { false }
              content = instance_double(Stash::Wrapper::StashWrapper)
              allow(r).to receive(:content) { content }
              expect(@metadata_mapper).to receive(:to_index_document).with(content) { { id: records[i].identifier } }
            end

            # delete failure
            delete_error = RSolr::Error::InvalidResponse.new(instance_double(Net::HTTP::Get), instance_double(Net::HTTPResponse))
            delete_error.define_singleton_method(:to_s) { 'mock InvalidResponse for delete' }
            expect(@solr).to receive(:delete_by_id).with(records[0].identifier).and_raise(delete_error)

            # delete success
            expect(@solr).to receive(:delete_by_id).with(records[1].identifier)

            # add failure
            add_error = RSolr::Error::InvalidResponse.new(instance_double(Net::HTTP::Get), instance_double(Net::HTTPResponse))
            add_error.define_singleton_method(:to_s) { 'mock InvalidResponse for add' }
            expect(@solr).to receive(:add).with(id: records[2].identifier).and_raise(add_error)

            # add success
            expect(@solr).to receive(:add).with(id: records[3].identifier)

            expect(@solr).to receive(:commit)

            results = []
            @indexer.index(records.lazy) do |result|
              expect(result).to be_a(Stash::Indexer::IndexResult)
              expect(result.record).to eq(records[results.length])
              results << result
            end

            expect(results.length).to eq(4)
            expect(results.map(&:success?)).to eq([false, true, false, true])
            expect(results.map(&:status)).to eq([IndexStatus::FAILED, IndexStatus::COMPLETED, IndexStatus::FAILED, IndexStatus::COMPLETED])
            expect(results.map(&:errors)).to eq([[delete_error], [], [add_error], []])
          end

          it 'returns an overall status based on the solr commit'

          it 'respects the configured batch size'

        end
      end
    end
  end
end
