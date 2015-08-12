require 'active_record'

module Stash
  module Harvester
    module Models
      STATUSES = [:pending, :in_progress, :completed, :failed]
      PENDING = STATUSES.index(:pending)

      class HarvestJob < ActiveRecord::Base
        has_many :harvested_records
        has_many :index_jobs

        enum status: STATUSES
      end

      class HarvestedRecord < ActiveRecord::Base
        belongs_to :harvest_job
        has_many :indexed_records

        # TODO: test me
        def self.find_last_indexed
          joins(:indexed_records).where(status: :completed).order(timestamp: :desc).first
        end

        # TODO: test me
        def self.find_first_failed
          joins(:indexed_records).where(status: :failed).order(:timestamp).last
        end
      end

      class IndexJobs < ActiveRecord::Base
        belongs_to :harvest_job
        has_many :indexed_records

        enum status: STATUSES
      end

      class IndexedRecord < ActiveRecord::Base
        belongs_to :harvested_record
        belongs_to :index_job

        enum status: STATUSES
      end
    end
  end
end
