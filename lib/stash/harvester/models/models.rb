require 'active_record/base'
require 'active_record/migration'

module Stash
  module Harvester

    STATUSES = [:pending, :in_progress, :completed, :failed]
    PENDING = STATUSES.index(:pending)

    class HarvestJob < ActiveRecord::Base
      has_many :harvested_records
      has_many :index_jobs
    end

    class HarvestedRecord < ActiveRecord::Base
      belongs_to :harvest_job
      has_many :indexed_records
    end

    class IndexJobs < ActiveRecord::Base
      belongs_to :harvest_job
      has_many :indexed_records
    end

    class IndexedRecord < ActiveRecord::Base
      belongs_to :harvested_record
      belongs_to :index_job
    end

  end
end
