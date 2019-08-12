# frozen_string_literal: true

require 'httparty'

module StashEngine
  module StatusDashboard

    class NotifierService < DependencyCheckerService

      LOG_FILE = '/dryad/apps/ui/shared/cron/logs/stash-notifier.log'.freeze
      DATE_TIME_MATCHER = /[0-9]{4}\-[0-9]{2}\-[0-9]{2}T([0-9]{2}:){2}[0-9]{2}/.freeze

      def ping_dependency
        super
        record_status(online: false, message: "No log file found at '#{LOG_FILE}'.") unless File.exist?(LOG_FILE)
        return false unless File.exist?(LOG_FILE)

        online = true
        contents = File.open(LOG_FILE).to_a
        online = false if contents.empty?
        last_run_date = Time.parse(line.match(DATE_TIME_MATCHER).to_s) if online
        online = last_run_date >= (Time.now - 15.minutes)
        msg = "The Notifier service has not updated its log since #{last_run_date}." if !online && last_run_date.present?
        msg = "The Notifier service has an empty log." if !online && !last_run_date.present?
        record_status(online: online, message: msg)
        online
      rescue StandardError => e
        record_status(online: false, message: e.to_s)
        false
      end

    end

  end
end
