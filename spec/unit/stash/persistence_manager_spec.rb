require 'spec_helper'

module Stash
  describe PersistenceManager do

    before(:each) do
      @mgr = PersistenceManager.new
      @completed = Stash::Indexer::IndexStatus::COMPLETED
    end

    describe '#begin_harvest_job' do
      it 'is abstract' do
        expect do
          @mgr.begin_harvest_job(from_time: nil, until_time: nil, query_url: URI('http://example.org/oai?verb=ListRecords'))
        end.to raise_error(NoMethodError)
      end
    end

    describe '#end_harvest_hob' do
      it 'is abstract' do
        expect do
          @mgr.end_harvest_job(harvest_job_id: 1, status: @completed)
        end.to raise_error(NoMethodError)
      end
    end

    describe '#record_harvested_record' do
      it 'is abstract' do
        expect do
          @mgr.record_harvested_record(harvest_job_id: 1, identifier: 'doi:10.123/456', timestamp: Time.now)
        end.to raise_error(NoMethodError)
      end
    end

    describe '#begin_index_job' do
      it 'is abstract' do
        expect do
          @mgr.begin_index_job(harvest_job_id: 1, solr_url: URI('http://example.org/solr'))
        end.to raise_error(NoMethodError)
      end
    end

    describe '#end_index_job' do
      it 'is abstract' do
        expect do
          @mgr.end_index_job(index_job_id: 1, status: @completed)
        end.to raise_error(NoMethodError)
      end
    end

    describe '#record_indexed_record' do
      it 'is abstract' do
        expect do
          @mgr.record_indexed_record(index_job_id: 1, harvested_record_id: 123, status: @completed)
        end.to raise_error(NoMethodError)
      end
    end

    describe '#find_newest_indexed_timestamp' do
      it 'is abstract' do
        expect do
          @mgr.find_newest_indexed_timestamp
        end.to raise_error(NoMethodError)
      end
    end

    describe '#find_oldest_failed_timestamp' do
      it 'is abstract' do
        expect do
          @mgr.find_oldest_failed_timestamp
        end.to raise_error(NoMethodError)
      end
    end
  end
end
