require 'stash/persistence_manager'
require 'stash/persistence_config'

module Stash
  class NoOpPersistenceManager < PersistenceManager
    def begin_harvest_job(from_time:, until_time:, query_url:); 0; end
    def end_harvest_job(harvest_job_id:, status:); end
    def record_harvested_record(harvest_job_id:, identifier:, timestamp:, deleted: false); 0; end
    def begin_index_job(harvest_job_id:, solr_url:); 0; end
    def end_index_job(index_job_id:, status:); end
    def record_indexed_record(index_job_id:, harvested_record_id:, status:); end
    def find_newest_indexed_timestamp; end
    def find_oldest_failed_timestamp; end
  end

  class NoOpPersistenceConfig < PersistenceConfig
    can_build_if do |config|
      config == 'none'
    end

    def initialize(_args); end

    def description
      to_s
    end

    def create_manager
      NoOpPersistenceManager.new
    end

  end
end
