require 'db_spec_helper'

module Stash
  module Harvester
    module Models

      describe HarvestedRecord, type: :model, fixture: 'harvested_record_spec' do

        it 'should have a working fixture' do
          count = 0
          HarvestJob.find_each do |job|
            puts job.query_url
            puts job.start_time
            puts job.end_time
            puts job.status
            count += 0
          end
          expect(count).to eq(4)
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
