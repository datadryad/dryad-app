require 'stash/harvester'
require 'stash/indexer'

module Stash
  class HarvestAndIndexJob
    attr_reader :harvest_task
    attr_reader :indexer
    attr_reader :persistence_mgr

    def initialize(source_config:, index_config:, metadata_mapper:, persistence_manager:, from_time: nil, until_time: nil)
      @harvest_task = source_config.create_harvest_task(from_time: from_time, until_time: until_time)
      @indexer = index_config.create_indexer(metadata_mapper)
      @persistence_mgr = persistence_manager
    end

    def harvest_and_index(&block)
      harvested_records = harvest
      indexer.index(harvested_records, &block)
    end

    private

    def harvest
      job_id = begin_harvest_job(harvest_task)
      status = Indexer::IndexStatus::COMPLETED
      begin
        harvest_task.harvest_records
      rescue => e
        status = Indexer::IndexStatus::FAILED
        raise e
      ensure
        end_harvest_job(job_id, status)
      end
    end

    def begin_harvest_job(task)
      persistence_mgr.begin_harvest_job(
        from_time: task.from_time,
        until_time: task.until_time,
        query_url: task.query_uri
      )
    end

    def end_harvest_job(job_id, status)
      persistence_mgr.end_harvest_job(harvest_job_id: job_id, status: status)
    end

  end
end
