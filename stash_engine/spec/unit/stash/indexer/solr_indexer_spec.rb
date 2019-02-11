require 'spec_helper'
require 'stash/indexer/solr_indexer'

module Stash
  module Indexer
    describe SolrIndexer do

      before(:each) do
        @my_url = 'http://uc3-dryadsolr-dev.cdlib.org:8983/solr/geoblacklight/'
        @my_indexer = Stash::Indexer::SolrIndexer.new(solr_url: 'http://uc3-dryadsolr-dev.cdlib.org:8983/solr/geoblacklight/')

        my_logger = instance_double('Logger')
        allow(my_logger).to receive(:error).and_return(nil)
        allow(my_logger).to receive(:debug).and_return(nil)

        allow(Rails).to receive(:logger).and_return(my_logger)
      end

      describe '#initialize' do

        it 'initializes with an rsolr instance' do
          expect(@my_indexer.solr).to be_instance_of(RSolr::Client)
        end

        it 'saves the solr url' do
          expect(@my_indexer.solr.uri.to_s).to eql(@my_url)
        end
      end

      describe 'index_document' do

        # the solr hash is tested elsewhere in its own unit tests

        it 'returns true if a correct response is returned by SOLR' do
          allow(@my_indexer.solr).to receive(:add).and_return('responseHeader' => { 'status' => 0 })
          expect(@my_indexer.index_document(solr_hash: {})).to be(true)
        end

        it 'returns false if there is a bad response' do
          allow(@my_indexer.solr).to receive(:add).and_return('responseHeader' => { 'status' => 666 })
          expect(@my_indexer.index_document(solr_hash: {})).to be(false)
        end

        it 'returns false if there is a standard exception' do
          allow(@my_indexer.solr).to receive(:add).and_raise(Net::HTTPGatewayTimeOut)
          expect(@my_indexer.index_document(solr_hash: {})).to be(false)
        end
      end

      describe 'delete_document' do
        it 'returns true if a correct response is returned by SOLR' do
          allow(@my_indexer.solr).to receive(:delete_by_id).and_return('responseHeader' => { 'status' => 0 })
          allow(@my_indexer.solr).to receive(:commit).and_return(true)
          expect(@my_indexer.delete_document(doi: '')).to be(true)
        end

        it 'returns false if there is a bad response' do
          allow(@my_indexer.solr).to receive(:delete_by_id).and_return('responseHeader' => { 'status' => 666 })
          allow(@my_indexer.solr).to receive(:commit).and_return(true)
          expect(@my_indexer.delete_document(doi: '')).to be(false)
        end

        it 'returns false if there is a standard exception' do
          allow(@my_indexer.solr).to receive(:delete_by_id).and_raise(Net::HTTPGatewayTimeOut)
          expect(@my_indexer.delete_document(doi: '')).to be(false)
        end
      end

    end
  end
end
