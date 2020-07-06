# frozen_string_literal: true

require 'httparty'

module StashEngine
  module StatusDashboard

    class NotifierService < DependencyCheckerService

      LOG_FILE = '/dryad/apps/ui/shared/cron/logs/stash-notifier.log'

      # rubocop:disable Metrics/CyclomaticComplexity
      def ping_dependency
        super
        record_status(online: false, message: "No log file found at '#{LOG_FILE}'.") unless File.exist?(LOG_FILE)
        return false unless File.exist?(LOG_FILE)

        last_run_date = extract_last_log_date(LOG_FILE)
        log_err = extract_log_err(LOG_FILE)
        online = last_run_date.present? && last_run_date >= (Time.now - 15.minutes) && !log_err
        msg = ''
        msg += "The Notifier service last updated its log at '#{last_run_date}'. " unless online
        msg += "Notifier log has error: #{log_err}" if log_err.present?
        record_status(online: online, message: msg)
        online
      rescue StandardError => e
        record_status(online: false, message: e.to_s)
        false
      end
      # rubocop:enable Metrics/CyclomaticComplexity

    end

  end
end
