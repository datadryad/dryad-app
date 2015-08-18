require 'db_spec_helper'

module Stash
  module Harvester
    module Models

      describe HarvestedRecord do

        before :each do
          # ------------------------------
          # completed harvest

          @harvest_job_completed = create(:indexed_harvest_job, record_count: 3, from_time: nil, start_time: Time.utc(2015, 7, 1))
          @harvested_records_completed = @harvest_job_completed.harvested_records
          @index_job_completed = @harvest_job_completed.index_jobs.first
          @indexed_records_completed = @index_job_completed.indexed_records

          # ------------------------------
          # Incremental synchronization (indexing failed)

          @harvest_job_failed = create(:indexed_harvest_job, record_count: 3, from_time: Time.utc(2015, 7, 1, 10), start_time: Time.utc(2015, 8, 1), index_record_status: :failed)
          @harvested_records_failed = @harvest_job_failed.harvested_records
          @index_job_failed = @harvest_job_failed.index_jobs.first
          @indexed_records_failed = @index_job_failed.indexed_records

          # ------------------------------
          # Incremental synchronization (indexing pending)

          @harvest_job_pending = create(:indexed_harvest_job, record_count: 3, from_time: Time.utc(2015, 7, 1, 10), start_time: Time.utc(2015, 8, 1), index_job_status: :in_progress, index_record_status: :pending)
          @harvested_records_pending = @harvest_job_pending.harvested_records
          @index_job_pending = @harvest_job_pending.index_jobs.first
          @indexed_records_pending = @index_job_pending.indexed_records
        end

        describe '#find_last_indexed' do

          it 'finds only index-completed records' do
            last_indexed = HarvestedRecord.find_last_indexed

            indexed_records = last_indexed.indexed_records
            expect(indexed_records.count).to eq(1)

            indexed_record = indexed_records.first
            expect(indexed_record.completed?).to be true

            expect(last_indexed).to eq(@harvested_records_completed.last)
          end

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
