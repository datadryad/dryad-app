require 'logger'

module Stash
  module Repo

    # Encapsulates a submission result
    class SubmissionResult
      attr_reader :resource_id
      attr_reader :message
      attr_reader :error

      # @param resource_id [Integer] the ID of the submitted resource
      # @param message [String, nil] an optional log message
      # @param error [Error, nil] an error indicating a failed result
      def initialize(resource_id:, message: nil, error: nil)
        @resource_id = resource_id
        @message = message
        @error = error
      end

      def success?
        error.nil?
      end

      def log_to(logger)
        success? ? log_success_to(logger) : log_failure_to(logger)
      end

      protected

      def log_success_to(logger)
        msg = "Submission successful for resource #{resource_id}"
        msg << ': ' << message if message
        logger.info(msg)
      end

      def log_failure_to(logger)
        msg = "Submission failed for resource #{resource_id}"
        msg << ': ' << message if message
        msg << "\n" << error.to_s
        msg << "\n" << backtrace_str if backtrace_str
        logger.error(msg)
      end

      def backtrace_str
        return unless error.respond_to?(:backtrace)
        backtrace = error.backtrace
        return unless backtrace
        backtrace.join("\n")
      end

    end
  end
end
