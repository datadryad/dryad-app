require 'logger'

module Stash
  module Repo
    # Encapsulates a submission result
    class SubmissionResult
      attr_reader :resource_id, :request_desc, :message, :error
      attr_accessor :deferred

      # @param resource_id [Integer] the ID of the submitted resource
      # @param request_desc [String, nil] a description of the request that produced this result
      # @param message [String, nil] an optional log message
      # @param error [Error, nil] an error indicating a failed result
      def initialize(resource_id:, request_desc:, message: nil, error: nil)
        @resource_id = resource_id
        @request_desc = request_desc
        @message = message
        @error = error

        # for asynchronous processing, gets set if the request is deferred (which is all the time now, but previously
        # some items were submitted synchronously)
        @deferred = true
      end

      def success?
        error.nil?
      end

      def deferred?
        @deferred
      end

      def log_to(logger)
        success? ? log_success_to(logger) : log_failure_to(logger)
      end

      def self.success(resource_id:, request_desc:, message: nil)
        SubmissionResult.new(resource_id: resource_id, request_desc: request_desc, message: message)
      end

      def self.failure(resource_id:, request_desc:, error: nil)
        SubmissionResult.new(resource_id: resource_id, request_desc: request_desc, error: error)
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
        msg << "\n" << error.full_message if backtrace_str
        logger.error(msg)
      end

      def backtrace_str
        return unless error.respond_to?(:backtrace)

        error.full_message
      end
    end
  end
end
