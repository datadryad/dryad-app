require 'stash/indexer/index_status'

module Stash
  # TODO: do we need an abstract version, or just the concrete AR version?
  class PersistenceManager

    # @return [Integer] the ID of the created job
    def begin_harvest_job(from_time:, until_time:, query_url:) # rubocop:disable Lint/UnusedMethodArgument
      raise NoMethodError, "#{self.class} should implement #begin_harvest_job, but it doesn't"
    end

    # @return [void]
    def end_harvest_job(harvest_job_id:, status:) # rubocop:disable Lint/UnusedMethodArgument
      raise NoMethodError, "#{self.class} should implement #end_harvest_job, but it doesn't"
    end

    # @return [Integer] the ID of the created record
    def record_harvested_record(harvest_job_id:, identifier:, timestamp:, deleted: false) # rubocop:disable Lint/UnusedMethodArgument
      raise NoMethodError, "#{self.class} should implement #record_harvested_record, but it doesn't"
    end

    # @return [Integer] the ID of the created job
    def begin_index_job(harvest_job_id:, solr_url:) # rubocop:disable Lint/UnusedMethodArgument
      raise NoMethodError, "#{self.class} should implement #begin_index_job, but it doesn't"
    end

    # @return [void]
    def end_index_job(index_job_id:, status:) # rubocop:disable Lint/UnusedMethodArgument
      raise NoMethodError, "#{self.class} should implement #end_index_job, but it doesn't"
    end

    # @return [void]
    def record_indexed_record(index_job_id:, harvested_record_id:, status:) # rubocop:disable Lint/UnusedMethodArgument
      raise NoMethodError, "#{self.class} should implement #record_indexed_record, but it doesn't"
    end

    # @return [Time, nil] the timestamp of the newest indexed record, or nil if no failed records exist
    def find_newest_indexed_timestamp
      raise NoMethodError, "#{self.class} should implement #find_newest_indexed_timestamp, but it doesn't"
    end

    # @return [Time, nil] the timestamp of the oldest failed record, or nil if no failed records exist
    def find_oldest_failed_timestamp
      raise NoMethodError, "#{self.class} should implement #find_oldest_failed_timestamp, but it doesn't"
    end
  end
end
