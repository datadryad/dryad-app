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
      persistence_mgr.begin_harvest_job(
        from_time: harvest_task.from_time,
        until_time: harvest_task.until_time,
        query_url: harvest_task.query_uri)
      harvested_records = harvest_task.harvest_records
      indexer.index(harvested_records, &block)
    end

  end
end
