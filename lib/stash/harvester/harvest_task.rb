module Stash
  module Harvester
    class HarvestTask

      attr_reader :from_time
      attr_reader :until_time

      # Constructs a new +HarvestTask+ with the specified datetime range.
      # Note that the datetime range must be in UTC.
      #
      # @param from_time [Time, nil] the start (inclusive) of the datestamp range for selective harvesting.
      #   If +from_time+ is omitted, harvesting will extend back to the earliest datestamp in the
      #   repository. (Optional)
      # @param until_time [Time, nil] the end (inclusive) of the datestamp range for selective harvesting.
      #   If +until_time+ is omitted, harvesting will extend forward to the latest datestamp in the
      #   repository. (Optional)
      # @raise [RangeError] if +from_time+ is later than +until_time+.
      # @raise [ArgumentError] if +from_time+ or +until_time+ is not in UTC.
      def initialize(from_time: nil, until_time: nil)
        @from_time, @until_time = valid_range(from_time, until_time)
      end

      def harvest_records
        fail "#{self.class} should override #harvest_records to harvest records, but it doesn't"
      end

      # ------------------------------
      # Parameter validators

      def utc_or_nil(time)
        if time && !time.utc?
          fail ArgumentError, "time #{time}| must be in UTC"
        else
          time
        end
      end

      def valid_range(from_time, until_time)
        if from_time && until_time && from_time.to_i > until_time.to_i
          fail RangeError, "from_time #{from_time} must be <= until_time #{until_time}"
        else
          [utc_or_nil(from_time), utc_or_nil(until_time)]
        end
      end

      # ------------------------------------------------------------
      # Private methods

      private

      # ------------------------------
      # Conversions

      def to_uri(url)
        (url.is_a? URI) ? url : URI.parse(url)
      end

    end
  end
end
