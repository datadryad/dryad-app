require 'db_spec_helper'

module Stash
  module Harvester
    module Models

      describe HarvestedRecord do

        before :each do
          @record_count = 3

          @harvest_job_completed = create(:indexed_harvest_job, record_count: @record_count, from_time: nil, start_time: Time.utc(2015, 7, 1))
          @harvested_records_completed = @harvest_job_completed.harvested_records

          @harvest_job_failed = create(
            :indexed_harvest_job,
            record_count: @record_count + 1,
            from_time: Time.utc(2015, 7, 1, 10),
            start_time: Time.utc(2015, 8, 1),
            index_record_status: :failed
          )
          @harvested_records_failed = @harvest_job_failed.harvested_records
        end

        describe '#find_newest_indexed' do
          it 'finds the newest indexed record' do
            last_indexed = HarvestedRecord.find_newest_indexed

            indexed_records = last_indexed.indexed_records
            expect(indexed_records.count).to eq(1)

            indexed_record = indexed_records.first
            expect(indexed_record.completed?).to be true

            expect(last_indexed).to eq(@harvested_records_completed.last)
          end
        end

        describe '#find_oldest_failed' do
          it 'finds the oldest failed record' do
            oldest_failed = HarvestedRecord.find_oldest_failed

            indexed_records = oldest_failed.indexed_records
            expect(indexed_records.count).to eq(1)

            indexed_record = indexed_records.first
            expect(indexed_record.failed?).to be true

            expect(oldest_failed).to eq(@harvested_records_failed.first)
          end

          it 'ignores index-failed records with subsequently successful indexes' do
            reharvest_from = @harvested_records_failed.first.timestamp
            reharvest_job = create(
              :harvest_job,
              from_time: reharvest_from,
              query_url: "http://oai.datacite.org/oai?verb=ListRecords&metadataPrefix=oai_dc#{'&from_time=' + reharvest_from.utc.xmlschema}",
              start_time: Time.utc(2015, 9, 1),
              end_time: Time.utc(2015, 9, 1, @record_count)
            )

            reindex_job = create(
              :index_job,
              solr_url: 'http://solr.example.org/',
              harvest_job: reharvest_job,
              start_time: Time.utc(2015, 9, 1, @record_count),
              end_time: Time.utc(2015, 9, 2),
              status: :completed
            )

            still_failed = []
            @harvested_records_failed.each_with_index do |hr, index|
              if index.even?
                reharvested_record = create(
                  :harvested_record,
                  harvest_job: reharvest_job,
                  identifier: hr.identifier,
                  timestamp: Time.utc(2016, 1, 1, index),
                  deleted: hr.deleted
                )
                create(
                  :indexed_record,
                  index_job: reindex_job,
                  harvested_record: reharvested_record,
                  submitted_time: Time.utc(2015, 9, 1, index),
                  status: :completed
                )
              else
                still_failed << hr
              end
            end

            later_failure = create(
              :harvested_record,
              harvest_job: reharvest_job,
              identifier: 'elvis',
              timestamp: Time.utc(2016, 2, 1),
              deleted: false
            )

            create(
              :indexed_record,
              index_job: reindex_job,
              harvested_record: later_failure,
              submitted_time: Time.utc(2015, 9, 2),
              status: :failed
            )

            # should be the first even-numbered record
            oldest_failed = HarvestedRecord.find_oldest_failed

            expect(oldest_failed).to eq(still_failed.first)
          end

        end
      end
    end
  end
end
