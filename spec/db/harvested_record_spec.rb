require 'db_spec_helper'

module Stash
  module Harvester
    module Models

      describe HarvestedRecord do

        before :each do
          @hj_initial_harvest = create(
            :harvest_job,
            query_url: 'http://oai.datacite.org/oai?verb=ListRecords&metadataPrefix=oai_dc',
            start_time: Time.utc(2015, 7, 1),
            end_time: Time.utc(2015, 7, 1, 10),
            status: :completed
          )
          expect(@hj_initial_harvest).to be_persisted

          @hj_incremental_sync = create(
            :harvest_job,
            query_url: 'http://oai.datacite.org/oai?verb=ListRecords&metadataPrefix=oai_dc&from_time=2015-07-01T10:00:00Z',
            start_time: Time.utc(2015, 7, 1),
            end_time: Time.utc(2015, 7, 1, 10),
            status: :completed
          )
          expect(@hj_incremental_sync).to be_persisted
        end

        it 'should have a working fixture' do
          count = 0
          HarvestJob.find_each do |job|
            puts job.query_url
            puts job.start_time
            puts job.end_time
            puts job.status
            count += 0
          end
          expect(count).to eq(2)
        end

        describe '#find_last_indexed' do
          it 'finds only index-completed records'
          it 'finds only the most recent such record'
        end

        describe '#find_last_indexed' do
          it 'finds only index-failed records'
          it 'finds only the oldest such record'
        end
      end
    end
  end
end
