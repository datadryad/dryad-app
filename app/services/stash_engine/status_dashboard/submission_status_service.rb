# frozen_string_literal: true

# require 'httparty'

module StashEngine
  module StatusDashboard
    class SubmissionStatusService < DependencyCheckerService

      LOG_FILE = '/dryad/apps/ui/shared/cron/logs/merritt_status_updater.log'

      def ping_dependency
        super
        record_status(online: false, message: "No log file found at '#{LOG_FILE}'.") unless File.exist?(LOG_FILE)
        return false unless File.exist?(LOG_FILE)

        last_run_date = extract_last_log_date(LOG_FILE)
        log_err = extract_log_err(LOG_FILE)
        # A failure to process the notifier's PATCH call is not a failure in the notifier itself
        log_err = nil if log_err.match(/PATCH to http/)

        online = last_run_date.present? && last_run_date >= (Time.now - 15.minutes).utc && !log_err.present?
        msg = ''
        msg += "The Merritt submission status service last updated its log at '#{last_run_date}'. " unless online
        msg += "Notifier log has error: #{log_err}" if log_err.present?
        record_status(online: online, message: msg)
        online
      rescue StandardError => e
        record_status(online: false, message: e.to_s)
        false
      end
    end
  end
end
