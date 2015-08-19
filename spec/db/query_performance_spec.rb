require 'db_spec_helper'

# TODO: move this into a separate category of spec (rake spec:performance?)
module Stash
  module Harvester
    module Models # rubocop:disable Metrics/ModuleLength
      describe HarvestedRecord do

        # RECORD_COUNT = 15000
        RECORD_COUNT = 50
        REPETITIONS = 100

        before(:each) do
          record_count = RECORD_COUNT
          create(:indexed_harvest_job, record_count: record_count, from_time: nil, start_time: Time.utc(2015, 7, 1))
          create(:indexed_harvest_job, record_count: record_count, from_time: Time.utc(2015, 7, 1, 10), start_time: Time.utc(2015, 8, 1), index_record_status: :failed)
          create(:indexed_harvest_job, record_count: record_count, from_time: Time.utc(2015, 7, 1, 10), start_time: Time.utc(2015, 8, 1), index_job_status: :in_progress, index_record_status: :pending)

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

        FIND_LAST_INDEXED = {
          find_by_sql_join: proc do
            query = 'SELECT harvested_records.*
                      FROM harvested_records
                        INNER JOIN indexed_records
                          ON harvested_records.id = indexed_records.harvested_record_id
                      WHERE indexed_records.status = 2
                      ORDER BY harvested_records.timestamp
                        DESC
                      LIMIT 1'
            HarvestedRecord.find_by_sql(query).first
          end,

          find_by_sql_subselect: proc do
            query = 'SELECT harvested_records.*
                      FROM harvested_records
                      WHERE harvested_records.id IN (
                        SELECT harvested_record_id
                        FROM indexed_records
                        WHERE indexed_records.status = 2
                      )
                      ORDER BY timestamp
                        DESC
                      LIMIT 1'
            HarvestedRecord.find_by_sql(query).first
          end,

          ar_join: proc do
            HarvestedRecord.joins(:indexed_records).where(indexed_records: { status: Status::COMPLETED }).order(timestamp: :desc).first
          end
        }

        describe 'find_last_indexed' do
          FIND_LAST_INDEXED.each do |method, query|
            it method do
              puts "===== #{method} ========================================"
              harvested_record = nil
              (0..REPETITIONS).each do
                harvested_record = query.call
              end
              expect(harvested_record).not_to be_nil
              puts "#{harvested_record.id}\t#{harvested_record.timestamp}\t#{harvested_record.indexed_records.map(&:status).join(', ')}"
            end
          end
        end

        FIND_FIRST_FAILED = {
          find_by_sql_subselect: proc do
            query = 'SELECT harvested_records.*
                      FROM harvested_records
                      WHERE harvested_records.id IN (
                        SELECT DISTINCT harvested_record_id
                        FROM indexed_records
                        WHERE indexed_records.status == 3
                      ) AND harvested_records.id NOT IN (
                        SELECT DISTINCT harvested_record_id
                        FROM indexed_records
                        WHERE indexed_records.status <> 3
                      )
                      ORDER BY harvested_records.timestamp
                        DESC
                      LIMIT 1'
            HarvestedRecord.find_by_sql(query).first
          end,

          find_by_sql_subselect_exists: proc do
            query = 'SELECT harvested_records.*
                      FROM harvested_records
                      WHERE exists(SELECT 1
                                   FROM indexed_records
                                   WHERE indexed_records.harvested_record_id = harvested_records.id)
                            AND NOT exists(SELECT 1
                                           FROM indexed_records
                                           WHERE indexed_records.harvested_record_id = harvested_records.id
                                                 AND indexed_records.status <> 3)
                      ORDER BY harvested_records.timestamp
                        DESC
                      LIMIT 1'
            HarvestedRecord.find_by_sql(query).first
          end,

          find_by_sql_join: proc do
            query = 'SELECT harvested_records.* FROM harvested_records
                      INNER JOIN indexed_records failed_records
                        ON harvested_records.id = failed_records.harvested_record_id AND failed_records.status == 3
                      LEFT JOIN indexed_records other_records
                        ON harvested_records.id = other_records.harvested_record_id AND other_records.status <> 3
                    WHERE other_records.id IS NULL
                    ORDER BY harvested_records.timestamp DESC LIMIT 1'
            HarvestedRecord.find_by_sql(query).first
          end
        }

        describe 'find_first_failed' do
          FIND_FIRST_FAILED.each do |method, query|
            it method do
              harvested_record = nil
              (0..REPETITIONS).each do
                harvested_record = query.call
              end
              expect(harvested_record).not_to be_nil
              puts "#{harvested_record.id}\t#{harvested_record.timestamp}\t#{harvested_record.indexed_records.map(&:status).join(', ')}"
            end
          end
        end

      end
    end
  end
end
