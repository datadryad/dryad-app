require 'stash/harvester'
require 'stash/indexer'

module Stash
  class HarvestAndIndexJob
    attr_reader :harvest_task
    attr_reader :indexer
    attr_reader :index_uri
    attr_reader :persistence_mgr

    def initialize(source_config:, index_config:, metadata_mapper:, persistence_manager:, from_time: nil, until_time: nil) # rubocop:disable Metrics/ParameterLists
      @harvest_task = source_config.create_harvest_task(from_time: from_time, until_time: until_time)
      @indexer = index_config.create_indexer(metadata_mapper)
      @index_uri = index_config.uri
      @persistence_mgr = persistence_manager
    end

    def harvest_and_index(&block)
      harvest_job_id = begin_harvest_job(harvest_task)
      harvested_records = harvest(harvest_job_id)
      index(harvested_records, harvest_job_id, &block)
    end

    private

    def harvest(job_id)
      status = Indexer::IndexStatus::COMPLETED
      begin
        harvest_task.harvest_records
      rescue Exception => e # rubocop:disable Lint/RescueException
        status = Indexer::IndexStatus::FAILED
        raise e
      ensure
        end_harvest_job(job_id, status)
      end
    end

    def index(harvested_records, harvest_job_id, &block)
      index_job_id = begin_index_job(harvest_job_id)
      status = Indexer::IndexStatus::COMPLETED
      begin
        do_index(harvested_records, harvest_job_id, index_job_id, &block)
      rescue Exception => e # rubocop:disable Lint/RescueException
        status = Indexer::IndexStatus::FAILED
        raise e
      ensure
        end_index_job(index_job_id, status)
      end
    end

    def do_index(harvested_records, harvest_job_id, index_job_id)
      indexer.index(harvested_records) do |result|
        harvested_record = result.record
        harvested_record_id = record_harvested(harvested_record, harvest_job_id)
        record_indexed(index_job_id, harvested_record_id, result.status)
        yield result if block_given?
      end
    end

    def begin_harvest_job(task)
      persistence_mgr.begin_harvest_job(
        from_time: task.from_time,
        until_time: task.until_time,
        query_url: task.query_uri
      )
    end

    def record_harvested(harvested_record, harvest_job_id)
      @persistence_mgr.record_harvested_record(
        harvest_job_id: harvest_job_id,
        identifier: harvested_record.identifier,
        timestamp: harvested_record.timestamp,
        deleted: harvested_record.deleted?
      )
    end

    def end_harvest_job(job_id, status)
      persistence_mgr.end_harvest_job(harvest_job_id: job_id, status: status)
    end

    def begin_index_job(harvest_job_id)
      persistence_mgr.begin_index_job(
        harvest_job_id: harvest_job_id,
        solr_url: index_uri
      )
    end

    def record_indexed(index_job_id, harvested_record_id, status)
      @persistence_mgr.record_indexed_record(
        index_job_id: index_job_id,
        harvested_record_id: harvested_record_id,
        status: status
      )
    end

    def end_index_job(job_id, status)
      persistence_mgr.end_index_job(index_job_id: job_id, status: status)
    end
  end
end
