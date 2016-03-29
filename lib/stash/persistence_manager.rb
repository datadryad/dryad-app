module Stash
  class PersistenceManager

    # @return [Integer] the ID of the created job
    def begin_harvest_job(from_time:, until_time:, query_url:)
      raise NoMethodError, "#{self.class} should implement #begin_harvest_job, but it doesn't"
    end

    # @return [void]
    def end_harvest_hob(harvest_job_id:, status:)
      raise NoMethodError, "#{self.class} should implement #end_harvest_job, but it doesn't"
    end

    # @return [Integer] the ID of the created record
    def record_harvested_record(harvest_job_id:, identifier:, timestamp:, deleted: false)
      raise NoMethodError, "#{self.class} should implement #record_harvested_record, but it doesn't"
    end

    # @return [Integer] the ID of the created job
    def begin_index_job(harvest_job_id:, solr_url:)
      raise NoMethodError, "#{self.class} should implement #begin_index_job, but it doesn't"
    end

    # @return [void]
    def end_index_job(index_job_id:, status:)
      raise NoMethodError, "#{self.class} should implement #end_index_job, but it doesn't"
    end

    # @return [Integer] the ID of the created record
    def record_indexed_record(index_job_id:, harvested_record_id:, status:)
      raise NoMethodError, "#{self.class} should implement #record_indexed_record, but it doesn't"
    end
  end
end
