module Stash
  module Harvester
    class HarvestTask

      attr_reader :from_time
      attr_reader :until_time

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

    end
  end
end
