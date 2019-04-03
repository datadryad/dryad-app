require 'stash/harvester'
require 'stash/indexer'
require 'rest-client'

module Stash
  class HarvestAndIndexJob # rubocop:disable Metrics/ClassLength:

    HARVEST_JOB_LOG_FORMAT = 'harvest job %d: %s'.freeze
    INDEX_JOB_LOG_FORMAT = '  index job %d: %s'.freeze
    HARVESTED_RECORD_LOG_FORMAT = 'harvested %s (timestamp: %s, deleted: %s) (harvest job: %d)'.freeze
    INDEXED_RECORD_LOG_FORMAT = '  indexed %s (timestamp: %s, deleted: %s; database id: %d): %s (index job: %d)'.freeze

    attr_reader :harvest_task
    attr_reader :indexer
    attr_reader :index_uri
    attr_reader :update_uri
    attr_reader :persistence_mgr

    def initialize(source_config:, index_config:, metadata_mapper:, persistence_manager:, update_uri: nil, from_time: nil, until_time: nil) # rubocop:disable Metrics/ParameterLists, Metrics/LineLength
      @harvest_task = source_config.create_harvest_task(from_time: from_time, until_time: until_time)
      @indexer = index_config.create_indexer(metadata_mapper)
      @index_uri = index_config.uri
      @persistence_mgr = persistence_manager
      @update_uri = update_uri
    end

    def harvest_and_index(&block)
      harvest_job_id = begin_harvest_job(harvest_task)
      harvested_records = harvest(harvest_job_id)
      index(harvested_records, harvest_job_id, &block)
    end

    def log
      Harvester.log
    end

    private

    def harvest(job_id)
      status = Indexer::IndexStatus::COMPLETED
      begin
        harvest_task.harvest_records
      rescue Exception => e # rubocop:disable Lint/RescueException
        status = Indexer::IndexStatus::FAILED
        log.warn("harvest job #{job_id}: #{e}")
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
        log.warn("  index job #{index_job_id}: #{e}")
        raise e
      ensure
        end_index_job(index_job_id, status)
      end
    end

    def do_index(harvested_records, harvest_job_id, index_job_id)
      count = 0
      indexer.index(harvested_records) do |result|
        harvested_record = result.record
        post_update(harvested_record) if result.success?
        harvested_record_id = record_harvested(harvested_record, harvest_job_id)
        record_indexed(index_job_id, harvested_record, harvested_record_id, result.status)
        count += 1
        yield result if block_given?
      end
      log.info("  indexed #{count} records")
    end

    def begin_harvest_job(task)
      log.info("Beginning harvest job for query URI #{task.query_uri}")
      persistence_mgr.begin_harvest_job(
        from_time: task.from_time,
        until_time: task.until_time,
        query_url: task.query_uri
      )
    end

    def post_update(harvested_record)
      return unless update_uri
      patch_uri = "#{update_uri}/#{harvested_record.wrapped_identifier}"
      record_identifier = harvested_record.identifier
      begin
        payload = { 'record_identifier' => record_identifier }.to_json
        RestClient.patch(patch_uri, payload, content_type: :json)
      rescue StandardError => e
        log.warn("Error PATCHing #{patch_uri || 'nil'} with {'record_identifier': '#{record_identifier || 'nil'}'}: #{e}")
      end
    end

    def record_harvested(harvested_record, harvest_job_id)
      log_harvested(harvest_job_id, harvested_record)
      @persistence_mgr.record_harvested_record(
        harvest_job_id: harvest_job_id,
        identifier: harvested_record.identifier,
        timestamp: harvested_record.timestamp,
        deleted: harvested_record.deleted?
      )
    end

    def log_harvested(harvest_job_id, harvested_record)
      msg = format(
        HARVESTED_RECORD_LOG_FORMAT,
        harvested_record.identifier,
        harvested_record.timestamp.xmlschema,
        harvested_record.deleted?,
        harvest_job_id
      )
      log.debug(msg)
    end

    def end_harvest_job(job_id, status)
      msg = format(HARVEST_JOB_LOG_FORMAT, job_id, status.value)
      status == Indexer::IndexStatus::COMPLETED ? log.info(msg) : log.warn(msg)
      persistence_mgr.end_harvest_job(harvest_job_id: job_id, status: status)
    end

    def begin_index_job(harvest_job_id)
      persistence_mgr.begin_index_job(
        harvest_job_id: harvest_job_id,
        solr_url: index_uri
      )
    end

    def record_indexed(index_job_id, harvested_record, harvested_record_id, status)
      log_indexed(index_job_id, harvested_record, harvested_record_id, status)
      @persistence_mgr.record_indexed_record(
        index_job_id: index_job_id,
        harvested_record_id: harvested_record_id,
        status: status
      )
    end

    def log_indexed(index_job_id, harvested_record, harvested_record_id, status)
      msg = format(
        INDEXED_RECORD_LOG_FORMAT,
        harvested_record.identifier,
        harvested_record.timestamp.xmlschema,
        harvested_record.deleted?,
        harvested_record_id,
        status.value,
        index_job_id
      )
      status == Indexer::IndexStatus::COMPLETED ? log.debug(msg) : log.warn(msg)
    end

    def end_index_job(job_id, status)
      msg = format(INDEX_JOB_LOG_FORMAT, job_id, status.value)
      status == Indexer::IndexStatus::COMPLETED ? log.info(msg) : log.warn(msg)
      persistence_mgr.end_index_job(index_job_id: job_id, status: status)
    end
  end
end
