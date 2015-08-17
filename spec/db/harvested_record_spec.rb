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

          @hj_incremental_sync = create(
            :harvest_job,
            query_url: 'http://oai.datacite.org/oai?verb=ListRecords&metadataPrefix=oai_dc&from_time=2015-07-01T10:00:00Z',
            start_time: Time.utc(2015, 7, 2),
            end_time: Time.utc(2015, 7, 2, 10),
            status: :completed
          )
        end

        it 'should have a working fixture' do
          expect(HarvestJob.count).to eq(2)
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
