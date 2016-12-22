require 'concurrent/async'

module StashEngine
  module Sword
    # Background job for asynchronous SWORD packaging
    class PackageJob

      def self.package_async(packager)
        Rails.logger.debug("Creating PackageJob for packager #{packager}")
        
        future = PackageJob.new(packager).async.submit
        future.add_observer(ResultLoggingObserver.new(packager))
        future
      end
      
      # Creates a new {PackageJob}.
      #
      # @param packager [#package] the packager. This can be any class, so long
      #   as its no-arg `#package` method produces a {SwordPackage}. For logging purposes,
      #   its `#to_s` method should include the resource ID, at minimum.
      def initialize(packager) # TODO: create explicit abstract packager with more debug info
        @packager = packager
      end
      
      # @return [SwordPackager] the package.
      def package
        packager.package
      end
      
      private
      
      attr_reader :packager

      # Logs the result of the packageJob, whether success or failure
      class ResultLoggingObserver
        def log
          Rails.logger
        end

        attr_reader :packager

        # Creates a new {ResultLoggingObserver}
        # @param packager [#package] the packager. This can be any class, so long
        #   as its no-arg `#package` method produces a {SwordPackage}. For logging purposes,
        #   its `#to_s` method should include the resource ID, at minimum.
        def initialize(packager) # TODO: create explicit abstract packager with more debug info
          @packager = packager
        end

        # Called by the `Concurrent::Async` framework on completion of the
        # {packageJob} async background task
        # @param time [Time] the time the job completed
        # @param value [SwordPackage, nil] the resource updated, or nil in the event of a failure
        # @param reason [Error, nil] any error, or nil in the event of success
        def update(time, value, reason)
          reason ? log_failure(time, reason) : log_success(time, value)
        end

        def log_failure(time, reason)
          log.warn("PackageJob for #{packager} failed at #{time}: #{reason}")
        end

        def log_success(time, package)
          zipfile = package.zipfile
          log.warn("PackageJob for #{packager} completed at #{time}: zipfile is #{zipfile}")
        end
      end

    end
  end
end
