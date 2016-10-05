module Stash
  module Harvester

    # Generic superclass of protocol-specific harvest tasks. Subclasses
    # should override {#harvest_records}, in conjunction with an appropriate
    # {SourceConfig}, to perform the actual harvest.
    #
    # @!attribute [r] config
    #   @return [SourceConfig] the configuration used by this task
    # @!attribute [r] from_time
    #   @return [Time, nil] the start (inclusive) of the datestamp range for selective harvesting.
    # @!attribute [r] until_time
    #   @return [Time, nil] the end (inclusive) of the datestamp range for selective harvesting.
    class HarvestTask

      attr_reader :config
      attr_reader :from_time
      attr_reader :until_time

      # Constructs a new `HarvestTask` with the specified datetime range.
      # Note that the datetime range must be in UTC.
      #
      # @param config [HarvestConfig] the configuration to be used by this task.
      # @param from_time [Time, nil] the start (inclusive) of the datestamp range for selective harvesting.
      #   If `from_time` is omitted, harvesting will extend back to the earliest datestamp in the
      #   repository. (Optional)
      # @param until_time [Time, nil] the end (inclusive) of the datestamp range for selective harvesting.
      #   If `until_time` is omitted, harvesting will extend forward to the latest datestamp in the
      #   repository. (Optional)
      # @raise [RangeError] if `from_time` is later than `until_time`.
      # @raise [ArgumentError] if `from_time` or `until_time` is not in UTC.
      def initialize(config:, from_time: nil, until_time: nil)
        @config = config
        @from_time, @until_time = valid_range(from_time, until_time)
      end

      # Provides access to the harvested records as a lazy enumeration. Implementations should make only
      # the minimum network requests needed to satisfy the needs of the client. For instance, in a protocol
      # that requires record-by-record downloading, if the client requests only the first record from the
      # enumeration, the implementation should only download that record. In a protocol that provides
      # 1000-record 'pages', the implementation should not download the second page unless the client asks
      # for more than 1000 records.
      #
      # @return [Enumerator::Lazy<HarvestedRecord>]
      #   A lazy enumerator of the harvested records
      def harvest_records
        raise NoMethodError, "#{self.class} should override #harvest_records, but it doesn't"
      end

      # Returns the URI queried by the harvest task, or the first URI queried if the harvest
      # requires multiple queries.
      #
      # @return [URI] the query URI
      def query_uri
        raise NoMethodError, "#{self.class} should override #query_uri, but it doesn't"
      end

      private

      def valid_range(from_time, until_time)
        invalid_range = from_time && until_time && from_time > until_time
        raise RangeError, "from_time #{from_time} must be <= until_time #{until_time}" if invalid_range
        [Util.utc_or_nil(from_time), Util.utc_or_nil(until_time)]
      end

    end
  end
end
