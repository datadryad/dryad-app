require 'active_record'
require 'models/status'
require 'models/harvest_job'

module Stash
  module Harvester
    module Models
      class HarvestedRecord < ActiveRecord::Base
        belongs_to :harvest_job
        has_many :indexed_records

        FIND_OLDEST_FAILED = <<-SQL.freeze
            SELECT
              all_records.*
            FROM
              (SELECT
                 harvested_records.id,
                 harvested_records.identifier,
                 MAX(harvested_records.timestamp),
                 indexed_records.status
               FROM
                 harvested_records,
                 indexed_records
               WHERE
                 harvested_records.id == indexed_records.harvested_record_id
               GROUP BY
                 identifier
               ORDER BY
                 timestamp DESC
              ) AS latest_BY_identifier,
              harvested_records AS all_records
            WHERE
              all_records.id = latest_BY_identifier.id AND
              latest_BY_identifier.status = #{Status::FAILED}
            ORDER BY
              all_records.timestamp
            LIMIT 1
        SQL

        def self.find_newest_indexed
          HarvestedRecord.joins(:indexed_records).where(indexed_records: { status: Status::COMPLETED }).order(timestamp: :desc).first
        end

        # 1. find the most recent harvest/index operation for each identifier
        #    (record identifier, *not* database ID), and
        # 2. of those, find the earliest with index status `FAILED`
        #
        # @return [HarvestedRecord] the oldest record that failed to index and
        #   was not later indexed successfully
        def self.find_oldest_failed
          HarvestedRecord.find_by_sql(FIND_OLDEST_FAILED).first
        end
      end
    end
  end
end
