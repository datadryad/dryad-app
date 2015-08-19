require 'active_record'
require_relative 'status'
require_relative 'harvest_job'

module Stash
  module Harvester
    module Models
      class HarvestedRecord < ActiveRecord::Base
        belongs_to :harvest_job
        has_many :indexed_records

        def self.find_last_indexed
          HarvestedRecord.joins(:indexed_records).where(indexed_records: { status: Status::COMPLETED }).order(timestamp: :desc).first
        end

        def self.find_first_failed
          query = 'SELECT harvested_records.* FROM harvested_records
                      INNER JOIN indexed_records failed_records
                        ON harvested_records.id = failed_records.harvested_record_id AND failed_records.status == 3
                      LEFT JOIN indexed_records other_records
                        ON harvested_records.id = other_records.harvested_record_id AND other_records.status <> 3
                    WHERE other_records.id IS NULL
                    ORDER BY harvested_records.timestamp DESC LIMIT 1'
          HarvestedRecord.find_by_sql(query).first
        end
      end
    end
  end
end
