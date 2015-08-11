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

    class CreateTables < ActiveRecord::Migration
      def change
        def self.up
          create_table :harvest_jobs do |t|
            t.datetime :from_time
            t.datetime :until_time
            t.text :query_url
            t.datetime :start_time
            t.datetime :end_time
            t.integer :status, default: PENDING
          end

          create_table :harvested_records do |t|
            t.text :identifier
            t.datetime :timestamp
            t.boolean :deleted
            t.text :content_path
            t.references :harvest_job
          end

          create_table :index_jobs do |t|
            t.references :harvest_job
            t.text :solr_url
            t.datetime :start_time
            t.datetime :end_time
            t.integer :status, default: PENDING
          end

          create_table :indexed_record do |t|
            t.references :index_job
            t.references :harvested_record
            t.datetime :submitted_time
            t.integer :status, default: PENDING
          end
        end

        def self.down
          drop_table :harvest_jobs
          drop_table :harvested_records
          drop_table :index_jobs
        end
      end
    end

  end
end
