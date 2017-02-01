require 'rails'
require 'active_record'
require 'concurrent/promise'

module Stash
  module Repo
    # Abstract superclass of background tasks. Should not contain any thread-unsafe
    # data or any data that cannot be serialized (e.g. pass database IDs, not
    # ActiveRecord models).
    class SubmissionJob
      attr_reader :resource_id

      def initialize(resource_id:)
        raise ArgumentError, "Invalid resource ID: #{resource_id || 'nil'}" unless resource_id && resource_id.is_a?(Integer)
        @resource_id = resource_id
      end

      # Executes this task and returns a result, or throws an error.
      # @return [SubmissionResult] the result of the task.
      def submit!
        raise NoMethodError, "#{self.class} should override #submit! to do some work, but it doesn't"
      end

      # Executes this task asynchronously and with its own ActiveRecord connection.
      # @return [Promise] a Promise that will provide the result of this task, or
      #   an error if any
      def submit_async
        Concurrent::Promise.new { ActiveRecord::Base.connection_pool.with_connection { submit! } }.execute
      end

      def log
        Rails.logger
      end
    end
  end
end
