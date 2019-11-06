# frozen_string_literal: true

require 'httparty'

module StashEngine
  module StatusDashboard

    class NotifierService < DependencyCheckerService

      LOG_FILE = '/dryad/apps/ui/shared/cron/logs/stash-notifier.log'

      def ping_dependency
        super
        record_status(online: false, message: "No log file found at '#{LOG_FILE}'.") unless File.exist?(LOG_FILE)
        return false unless File.exist?(LOG_FILE)

        last_run_date = extract_last_log_date(LOG_FILE)
        online = last_run_date.present? && last_run_date >= (Time.now - 15.minutes)
        msg = "The Notifier service has not updated its log since '#{last_run_date}'." unless online
        record_status(online: online, message: msg)
        online
      rescue StandardError => e
        record_status(online: false, message: e.to_s)
        false
      end

    end

  end
end
