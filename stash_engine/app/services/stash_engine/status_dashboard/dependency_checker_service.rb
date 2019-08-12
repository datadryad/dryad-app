# frozen_string_literal: true

module StashEngine
  module StatusDashboard

    class DependencyCheckerService

      DATE_TIME_MATCHER = /[0-9]{4}\-[0-9]{2}\-[0-9]{2}T([0-9]{2}:){2}[0-9]{2}/

      def initialize(**args)
        @dependency = StashEngine::ExternalDependency.find_by(abbreviation: args[:abbreviation])
      end

      def ping_dependency
        return nil unless @dependency.present?
        # Each implementation of this service must implement this method!
      end

      protected

      def record_status(message:, online:)
        return false unless @dependency.present?
        was_already_offline = @dependency.status != 1
        @dependency.update(status: online, error_message: message)
        report_outage if !online && !was_already_offline
        true
      end

      def report_outage
        UserMailer.dependency_offline(@dependency).deliver_now
      end

      def extract_last_log_date(log)
        contents = File.open(log).to_a
        last_run_date = Time.parse(line.match(DATE_TIME_MATCHER).to_s) unless contents.empty?
        last_run_date
      end

    end

  end
end
