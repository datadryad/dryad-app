require 'concurrent/async'

require 'stash_engine/sword/package'

module StashEngine
  module Sword
    # Background job for asynchronous SWORD packaging
    class PackageJob
      include Concurrent::Async

      # Creates a {PackageJob} and submits it on a background thread, logging the result.
      #
      # @param packager [Packager] the packager.
      # @return [Concurrent::Ivar] a future containing the completed {Package}, or an error
      def self.package_async(packager)
        resource = packager.resource
        tenant = packager.tenant
        log.debug("Creating PackageJob for resource: #{resource.id}, tenant: #{tenant.tenant_id}")

        future = PackageJob.new(packager).async.create_package
        future.add_observer(ResultLoggingObserver.new(packager))
        future
      end

      def self.log
        Rails.logger
      end

      def log
        Rails.logger
      end

      # Creates a new {PackageJob}.
      #
      # @param packager [Packager] the packager.
      def initialize(packager)
        @packager = packager
      end

      # @return [SwordPackager] the package.
      def create_package
        packager.create_package
      rescue => e
        report_error(e, packager.resource)
        raise
      end

      private

      def report_error(e, resource)
        log.error("#{e}\n#{e.backtrace.join("\n")}")
        resource.current_state = 'error' if resource

        title = packager.resource_title
        error_msg(e, resource, title).deliver_now

        request_host = packager.request_host
        request_port = packager.request_port

        failure_msg(resource, title, request_host, request_port, e).deliver_now
      end

      def error_msg(e, resource, title)
        UserMailer.error_report(resource, title, e)
      end

      def failure_msg(resource, title, request_host, request_port, e)
        if resource && resource.update_uri
          UserMailer.update_failed(resource, title, request_host, request_port, e)
        else
          UserMailer.create_failed(resource, title, request_host, request_port, e)
        end
      end

      attr_reader :packager

      # Logs the result of the packageJob, whether success or failure
      class ResultLoggingObserver
        def log
          Rails.logger
        end

        attr_reader :packager

        # Creates a new {ResultLoggingObserver}
        # @param packager [Packager] the packager.
        def initialize(packager)
          @packager = packager
        end

        def resource_id
          ((resource = packager.resource) && resource.id) || 'unknown'
        end

        def tenant_id
          ((tenant = packager.tenant) && tenant.tenant_id) || 'unknown'
        end

        # Called by the `Concurrent::Async` framework on completion of the
        # {packageJob} async background task
        # @param time [Time] the time the job completed
        # @param value [Package, nil] the resource updated, or nil in the event of a failure
        # @param reason [Error, nil] any error, or nil in the event of success
        def update(time, value, reason)
          reason ? log_failure(time, reason) : log_success(time, value)
        end

        def log_failure(time, reason)
          log.warn("PackageJob for resource: #{resource_id}, tenant: #{tenant_id} failed at #{time}: #{reason}")
        end

        def log_success(time, package)
          zipfile = package.zipfile
          log.info("PackageJob for resource: #{resource_id}, tenant: #{tenant_id} completed at #{time}: zipfile is #{zipfile}")
        end
      end

    end
  end
end
