# frozen_string_literal: true

module StashEngine
  module StatusDashboard

    class EventDataCitationService < DependencyCheckerService

      LOG_FILE = '/apps/dryad/apps/ui/shared/cron/logs/citation_populator.log'

      def ping_dependency
        super
        # It may take the script a while to run so we shouldn't really consider it a problem until Tuesday
        # Also, do not check any environments but production.
        if (Time.new.wday < 2 && Time.new.hour < 9) || Rails.env != 'production'
          record_status(online: true, message: 'Assumed online -- checks of logs start tuesday after running on Sunday')
          return true
        end

        result = check_citation_log(LOG_FILE)
        record_status(online: result[0], message: "#{result[1]} -- See #{LOG_FILE}")
        result[0]
      rescue StandardError => e
        record_status(online: false, message: e.to_s)
        false
      end

      # passing in log since it will make it easier to test in rspec if log path is passed in
      def check_citation_log(log)
        # check file exists
        return [false, 'Log file does not exist'] unless File.exist?(log)

        # read the end of the log file, last 1000 characters or the size of file
        f = File.new(log)
        seek_back = [f.size, 1_000].min
        f.seek(-seek_back, IO::SEEK_END)
        str = f.read

        matches = str.match(/Completed populating citations at (\d{4}-\d{2}-\d{2})/)

        return [false, "Log file doesn't end with completion message"] if matches.nil?

        last_run = Time.parse(matches[1]) # not super accurate to seconds, timezones, etc, but good enough to see if it ran in last week

        return [true, matches.to_s] if Time.new - last_run < 1.week

        [false, "Populating citations hasn't successfully completed this week"]
      end
    end

  end
end
