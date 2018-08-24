module StashEngine
  class CounterStat < ActiveRecord::Base
    belongs_to :identifier, class_name: 'StashEngine::Identifier'

    # this class wraps around some database accessors to cache them so we don't query the same stats more than once
    # per day because that is the max time that we update stats

    # these override the default ActiveRecord readers for these fields so it updates
    # the cache if necessary before reading (the read_attribute in the method, gets the
    # AR field instead of re-calling the same named method)
    def unique_investigation_count
      update_if_necessary
      read_attribute(:unique_investigation_count)
    end

    def unique_request_count
      update_if_necessary
      read_attribute(:unique_request_count)
    end

    def citation_count
      update_if_necessary
      read_attribute(:citation_count)
    end

    # try this doi, at least on test 10.7291/d1q94r
    # or how about this one? doi:10.7272/Q6Z60KZD
    # or this one has machine hits, I think.  doi:10.6086/D1H59V
    #
    # but unfortunately, we can really only display stats against production
    def update_if_necessary
      # we should have a counter stat already if it got to this class
      # only update stats if it's after the date of the last updated date for record
      return unless new_record? || updated_at.nil? || Time.new.localtime.to_date > updated_at.localtime.to_date
      update_usage!
      update_citation_count!

      self.updated_at = Time.new # seem to need this for some reason

      save!
    end

    def update_usage!
      usage = Stash::EventData::Usage.new(doi: identifier.identifier)
      self.unique_investigation_count = usage.unique_dataset_investigations_count
      self.unique_request_count = usage.unique_dataset_requests_count
    end

    def update_citation_count!
      cites = Stash::EventData::Citations.new(doi: identifier.identifier)
      self.citation_count = cites.results.count
    end

  end
end
