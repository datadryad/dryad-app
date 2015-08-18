require 'db_spec_helper'

module Stash
  module Harvester
    module Models

      describe HarvestedRecord do

        before :each do

          # TODO: Consolidate boilerplate into FactoryGirl factory

          # ------------------------------
          # completed harvest

          @harvest_job_completed = create(
            :harvest_job,
            query_url: 'http://oai.datacite.org/oai?verb=ListRecords&metadataPrefix=oai_dc',
            start_time: Time.utc(2015, 7, 1),
            end_time: Time.utc(2015, 7, 1, 10),
            status: :completed
          )

          @harvested_records_completed = Array.new(3) do |index|
            create(
              :harvested_record,
              harvest_job: @harvest_job_completed,
              identifier: "record#{index}",
              timestamp: Time.utc(2015, 6, 1 + index),
              deleted: false,
              content_path: "/tmp/record#{index}.xml"
            )
          end
          expect(HarvestedRecord.all.size).to eq(3)

          @index_job_completed = create(
            :index_job,
            harvest_job: @harvest_job_completed,
            start_time: Time.utc(2015, 7, 1, 10),
            end_time: Time.utc(2015, 7, 1, 10, 15),
            status: :completed
          )
          expect(IndexJob.all.size).to eq(1)
          expect(IndexJob.count(status: :completed)).to eq(1)
          expect(IndexJob.completed).not_to be_nil
          expect(IndexJob.completed.count).to eq(1)

          @indexed_records_completed = @harvested_records_completed.each_with_index.map do |harvested_record, index|
            create(
              :indexed_record,
              index_job: @index_job_completed,
              harvested_record: harvested_record,
              submitted_time: Time.utc(2015, 7, 10, 1 + index),
              status: :completed
            )
          end
          expect(IndexedRecord.all.size).to eq(3)
          expect(IndexedRecord.count(status: :completed)).to eq(3)
          expect(IndexedRecord.completed).not_to be_nil
          expect(IndexedRecord.completed.count).to eq(3)

          # ------------------------------
          # Incremental synchronization (indexing failed)

          @harvest_job_failed = create(
            :harvest_job,
            query_url: 'http://oai.datacite.org/oai?verb=ListRecords&metadataPrefix=oai_dc&from_time=2015-07-01T10:00:00Z',
            start_time: Time.utc(2015, 8, 1),
            end_time: Time.utc(2015, 8, 1, 10),
            status: :completed
          )

          @harvested_records_failed = Array.new(3) do |index|
            create(
              :harvested_record,
              harvest_job: @harvest_job_failed,
              identifier: "record#{index}",
              timestamp: Time.utc(2015, 7, 1 + index, 12),
              deleted: false,
              content_path: "/tmp/record#{index}.xml"
            )
          end

          @index_job_failed = create(
            :index_job,
            harvest_job: @harvest_job_failed,
            start_time: Time.utc(2015, 8, 1, 10),
            end_time: Time.utc(2015, 8, 1, 10, 15),
            status: :completed
          )

          @indexed_records_failed = @harvested_records_failed.each_with_index.map do |harvested_record, index|
            create(
              :indexed_record,
              index_job: @index_job_failed,
              harvested_record: harvested_record,
              submitted_time: Time.utc(2015, 8, 10, 1 + index),
              status: :failed
            )
          end

          # ------------------------------
          # Incremental synchronization (indexing pending)

          @harvest_job_pending = create(
            :harvest_job,
            query_url: 'http://oai.datacite.org/oai?verb=ListRecords&metadataPrefix=oai_dc&from_time=2015-07-01T10:00:00Z',
            start_time: Time.utc(2015, 9, 1),
            end_time: Time.utc(2015, 9, 1, 10),
            status: :completed
          )

          @harvested_records_pending = Array.new(3) do |index|
            create(
              :harvested_record,
              harvest_job: @harvest_job_pending,
              identifier: "record#{index}",
              timestamp: Time.utc(2015, 8, 1 + index, 12),
              deleted: false,
              content_path: "/tmp/record#{index}.xml"
            )
          end

          @index_job_pending = create(
            :index_job,
            harvest_job: @harvest_job_pending,
            start_time: Time.utc(2015, 9, 1, 10),
            end_time: Time.utc(2015, 9, 1, 10, 15),
            status: :in_progress
          )

          @indexed_records_pending = @harvested_records_pending.each_with_index.map do |harvested_record, index|
            create(
              :indexed_record,
              index_job: @index_job_pending,
              harvested_record: harvested_record,
              submitted_time: Time.utc(2015, 9, 10, 1 + index),
              status: :pending
            )
          end
        end

        describe '#find_last_indexed' do

          it 'finds only index-completed records' do
            last_indexed = HarvestedRecord.find_last_indexed
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
