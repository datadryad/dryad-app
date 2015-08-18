require 'db_spec_helper'

module Stash
  module Harvester
    module Models
      describe HarvestedRecord do

        RECORD_COUNT = 100
        REPETITIONS = 100

        before(:each) do

          # load_start_time = Time.now.utc

          record_count = RECORD_COUNT
          create(:indexed_harvest_job, record_count: record_count, from_time: nil, start_time: Time.utc(2015, 7, 1))
          create(:indexed_harvest_job, record_count: record_count, from_time: Time.utc(2015, 7, 1, 10), start_time: Time.utc(2015, 8, 1), index_record_status: :failed)
          create(:indexed_harvest_job, record_count: record_count, from_time: Time.utc(2015, 7, 1, 10), start_time: Time.utc(2015, 8, 1), index_job_status: :in_progress, index_record_status: :pending)

          # load_end_time = Time.now.utc
          #
          # seconds = (load_end_time.to_f - load_start_time.to_f)
          # puts "Load time in seconds #{sprintf('%.5g', seconds)}"

          @start_time = Time.now.utc
        end

        after(:each) do
          if @start_time
            @end_time = Time.now.utc
            total_seconds = (@end_time.to_f - @start_time.to_f)
            mean_millis = total_seconds * 1.0e3 / REPETITIONS
            puts "Mean time in millis: #{format('%.5g', mean_millis)}"
          end
          @start_time = nil
          @end_time = nil
        end

        def call_and_verify(query)
          harvested_record = nil
          (0..REPETITIONS).each do
            harvested_record = query.call
          end
          expect(harvested_record).not_to be_nil
          # puts harvested_record.inspect
          puts "#{harvested_record.id}\t#{harvested_record.timestamp}\t#{harvested_record.indexed_records.map(&:status).join(', ')}"
        end

        FIND_LAST_INDEXED = {

          find_by_sql_subselect: proc do
            query = '
              select
                harvested_records.*
              from
                harvested_records
              where
                harvested_records.id in (
                  select
                    harvested_record_id
                  from
                    indexed_records
                  where
                    indexed_records.status = 2
                )
              order by
                timestamp DESC
              limit 1
            '
            HarvestedRecord.find_by_sql(query).first
          end,

          find_by_sql_join: proc do
            query = '
              select
                harvested_records.*
              from
                harvested_records
              inner join
                indexed_records
              on
                harvested_records.id = indexed_records.harvested_record_id
              where
                indexed_records.status = 2
              order by
                harvested_records.timestamp DESC
              limit 1
            '
            HarvestedRecord.find_by_sql(query).first
          end,

          ar_join: proc do
            HarvestedRecord.joins(:indexed_records).where(indexed_records: { status: Status::COMPLETED }).order(timestamp: :desc).first
          end
        }

        describe 'find_last_indexed' do
          FIND_LAST_INDEXED.each do |method, query|
            it method do
              ActiveRecord::Base.logger.debug("===== #{method} ========================================")
              puts "===== #{method} ========================================"
              call_and_verify(query)
            end
          end
        end

        describe 'find_first_failed' do
          # it 'brute force' do
          #   harvested_record = HarvestedRecord.order(:timestamp).find do |r|
          #     r.indexed_records.all?(&:failed?)
          #   end
          #   expect(harvested_record).not_to be_nil
          #   puts "#{harvested_record.id}\t#{harvested_record.timestamp}\t#{harvested_record.indexed_records.map(&:status).join(', ')}"
          # end
        end

      end
    end
  end
end
