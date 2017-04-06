require 'config/factory'
require 'stash/util'

module Stash
  module Harvester

    # Superclass for configuration of any data source.
    #
    # @!attribute [r] source_uri
    #   @return [URI] the base URL of the repository.
    class SourceConfig
      include ::Config::Factory

      key :protocol

      attr_reader :source_uri

      # Constructs a new `SourceConfig` with the specified properties.
      #
      # @param source_url [URI, String] the base URL of the repository. *(Required)*
      # @raise [URI::InvalidURIError] if `source_url` is a string that is not a valid URI
      def initialize(source_url:)
        @source_uri = Util.to_uri(source_url)
      end

      # Constructs a new {HarvestTask} from this configuration. Implementors should
      # override this method to return an appropriate subclass of `HarvestTask` for
      # the data source.
      #
      # @param from_time [Time, nil] the start (inclusive) of the datestamp range for selective harvesting.
      #   If `from_time` is omitted, harvesting will extend back to the earliest datestamp in the
      #   repository. (Optional)
      # @param until_time [Time, nil] the end (inclusive) of the datestamp range for selective harvesting.
      #   If `until_time` is omitted, harvesting will extend forward to the latest datestamp in the
      #   repository. (Optional)
      # @raise [ArgumentError] if `from_time` or `until_time` is not in UTC.
      # @raise [RangeError] if `from_time` is later than `until_time`.
      # @return [HarvestTask] a task to harvest records for the specified time range
      def create_harvest_task(from_time: nil, until_time: nil) # rubocop:disable Lint/UnusedMethodArgument
        raise NoMethodError, "#{self.class} should override #create_harvest_task to create a HarvestTask, but it doesn't"
      end

      def description
        raise NoMethodError, "#{self.class} should override description, but it doesn't"
      end
    end
  end
end
