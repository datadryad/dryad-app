require 'rails'
require 'active_record'
require 'concurrent/promise'

module Stash
  module Repo
    # Abstract superclass of background tasks. Should not contain any thread-unsafe
    # data or any data that cannot be serialized (e.g. pass database IDs, not
    # ActiveRecord models). The state of ActiveRecord models outside the lifetime
    # of the `submit!` method is not guaranteed.
    class SubmissionJob
      attr_reader :resource_id

      def initialize(resource_id:)
        raise ArgumentError, "Invalid resource ID: #{resource_id || 'nil'}" unless resource_id.is_a?(Integer)
        @resource_id = resource_id
      end

      # Executes this task and returns a result, or throws an error. Any ActiveRecord
      # models needed by the task should be created in this method, and should not
      # be returned, yielded, thrown, or passed outside it.
      #
      # @return [SubmissionResult] the result of the task.
      def submit!
        raise NoMethodError, "#{self.class} should override #submit! to do some work, but it doesn't"
      end

      # Describes this submission job. This may include the resource ID, the type
      # of submission (create vs. update), and any configuration information (repository
      # URLs etc.) useful for debugging, but should not include any secret information
      # such as repository credentials, as it will be logged.
      # return [String] a description of the job
      def description
        raise NoMethodError, "#{self.class} should override #description to describe itself, but it doesn't"
      end

      # Executes this task asynchronously and with its own ActiveRecord connection.
      # @return [Promise<SubmissionResult>] a Promise that will provide the result of this job
      def submit_async
        Concurrent::Promise.new { ActiveRecord::Base.connection_pool.with_connection { submit! } }.execute
      end

      def log
        Rails.logger
      end
    end
  end
end
