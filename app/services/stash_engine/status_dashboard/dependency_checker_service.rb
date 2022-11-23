# frozen_string_literal: true

module StashEngine
  module StatusDashboard

    class DependencyCheckerService

      DATE_TIME_MATCHER = /[0-9]{4}-[0-9]{2}-[0-9]{2}T([0-9]{2}:){2}[0-9]{2}/
      LOG_ERR_MATCHER = /\[.*\] ERROR .*/

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
        report_outage(message) if !online && !was_already_offline
        true
      end

      def report_outage(message)
        UserMailer.dependency_offline(@dependency, message).deliver_now
      end

      def extract_log_err(log)
        contents = read_end_of_file(log)
        log_err = nil
        contents.reverse_each do |line|
          log_err = line.match(LOG_ERR_MATCHER).to_s
          break if log_err.present?
        end
        log_err
      end

      def extract_last_log_date(log)
        contents = read_end_of_file(log)
        last_run_date = nil
        contents.reverse_each do |line|
          date_match = line.match(DATE_TIME_MATCHER).to_s
          last_run_date = Time.parse(date_match) if date_match.present?
          break if last_run_date.present?
        end
        last_run_date
      end

      def read_end_of_file(log)
        f = File.new(log)
        f.seek(-4096, IO::SEEK_END) # before end of file
        f.read.strip.split("\n") # this reads just end of file, strips whitespace and converts to array of lines
      end

    end

  end
end
