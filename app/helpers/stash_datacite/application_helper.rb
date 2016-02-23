module StashDatacite
  module ApplicationHelper
    DEFAULT_TZ = 'America/Los_Angeles'

    def default_time(t)
        local_time(t).strftime("%m/%d/%y %I:%M %p")
    end

    def default_date(t)
      local_time(t).strftime("%m/%d/%y")
    end

    def local_time(t)
      tz = TZInfo::Timezone.get(DEFAULT_TZ)
      tz.utc_to_local(t)
    end

  end
end
