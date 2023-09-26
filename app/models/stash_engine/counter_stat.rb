module StashEngine
  class CounterStat < ApplicationRecord
    self.table_name = 'stash_engine_counter_stats'
    belongs_to :identifier, class_name: 'StashEngine::Identifier'

    # this class wraps around some database accessors to cache them so we don't query the same stats more than once
    # per week

    # all these "check" methods may be obsolete if we do scripts for population of everything ahead
    # and then we could just pull from database
    def check_unique_investigation_count
      # update_if_necessary
      unique_investigation_count
    end

    def check_unique_request_count
      # update_if_necessary
      unique_request_count
    end

    def check_citation_count
      # update_if_necessary
      citation_count
    end

    # views is a calculated stat of investigations minus requests since downloads are double-counted as requests also
    def views
      return 0 if check_unique_investigation_count.blank? || check_unique_request_count.blank?
      return 0 if check_unique_request_count > check_unique_investigation_count # if more downloads than views then something is wrong

      check_unique_investigation_count - check_unique_request_count
    end

    def downloads
      return 0 if check_unique_request_count.blank?

      check_unique_request_count
    end

    # try this doi, at least on test 10.7291/d1q94r
    # or how about this one? doi:10.7272/Q6Z60KZD
    # or this one has machine hits, I think.  doi:10.6086/D1H59V
    #
    # but unfortunately, we can really only display stats against production, because that is where stats are submitted
    def update_if_necessary
      # we should have a counter stat already if it got to this class
      # only update stats if it's a later calendar week than this record was updated
      return unless new_record? || updated_at.nil? || calendar_week(Time.new) > calendar_week(updated_at)

      update_usage!
      update_citation_count!
      self.updated_at = Time.new.utc # seem to need this for some reason, since not always updating automatically
      save!
    end

    def update_usage!
      usage = Stash::EventData::Usage.new(doi: identifier.identifier)
      # only update if usage going up, otherwise something is wrong and don't update
      return if usage.unique_dataset_investigations_count < unique_investigation_count

      self.unique_investigation_count = usage.unique_dataset_investigations_count
      self.unique_request_count = usage.unique_dataset_requests_count
    end

    def update_citation_count!
      cites = Stash::EventData::Citations.new(doi: identifier.identifier)
      self.citation_count = cites.results.count
    end

    # This will return the calendar year and week of that year for checking if something has been updated in the last calendar week.
    # If it is nil or not a time then return week 30 days ago (which will be out of caching period)
    def calendar_week(time)
      # %W calculates weeks based on starting Monday and not Sunday, %U is Sunday and %V is ???.
      # This produces year-week string.
      return 30.days.ago.strftime('%Y-%W') if time.nil? || !time.is_a?(Time)

      time.strftime('%Y-%W')
    end

  end
end
