# frozen_string_literal: true

module StashEngine
  module StatusDashboard

    class CounterCalculationService < DependencyCheckerService

      LOG_FILE = '/dryad/apps/ui/shared/cron/logs/counter.log'

      def ping_dependency
        super
        # Do not check unless it's Thursday or after in the week and after 9.
        # It takes the script a while to run so we shouldn't really consider it a problem until late in the week around Thurs.
        # Also, do not check any environments but production since we don't run and submit stats for others.
        if (Time.new.wday < 4 && Time.new.hour < 9) || Rails.env != 'production'
          record_status(online: true, message: "Assumed online, counter processing status isn't checked until Thursday to give time to run")
          return true
        end

        result = check_counter_log(LOG_FILE)
        record_status(online: result[0], message: "#{result[1]} -- See #{LOG_FILE}")
        result[0]
      rescue StandardError => e
        record_status(online: false, message: e.to_s)
        false
      end

      # passing in log since it will make it easier to test if log path is passed in
      def check_counter_log(log)
        # check file exists
        return [false, 'Log file does not exist'] unless File.exist?(log)

        # read the end of the log file
        f = File.new(log)
        # Read back approx the last 1,000 lines at 50 characters a line, one run of the processor is much more than this
        seek_back = [f.size, 50_000].min
        f.seek(-seek_back, IO::SEEK_END)
        str = f.read

        # check latest formatted date at beginning of a line like '2020-11-20 12:51:20'
        idx = str.rindex(/^\d{4}-\d{2}-\d{2}/)
        return [false, "Log file doesn't contain an output date"] if idx.nil?

        time = str[idx, 10].to_time
        return [false, "Counter hasn't successfully processed this week"] if ((Time.new - time) / 86_400) > 6

        # check it has 'submitted' at beginning of line in recent output
        submitted_idx = str.rindex(/^submitted/)
        return [false, "Counter doesn't seem to have successfully submitted this week"] if submitted_idx.nil?

        [true, 'The counter log indicates successful submission to DataCite this week']
      end
    end

  end
end
