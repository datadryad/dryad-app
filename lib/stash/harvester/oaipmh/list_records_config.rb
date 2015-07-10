module Stash
  module Harvester
    module OAIPMH

      # Encapsulates the configuration for a single +ListRecords+ operation.
      #
      # @!attribute [r] from_time
      #   @return [Time, nil] the start (inclusive) of the datestamp range for selective harvesting.
      # @!attribute [r] until_time
      #   @return [Time, nil] the end (inclusive) of the datestamp range for selective harvesting.
      # @!attribute seconds_granularity [r]
      #   @return [Boolean] whether to include the full time out to the second in the from / until time range. (Defaults to false, i.e., days granularity.)
      # @!attribute [r] metadata_prefix
      #   @return [String] the metadata prefix defining the metadata format requested from the repository.
      # @!attribute [r] set
      #   @return [String, nil] the colon-separated path to the set requested for selective harvesting.
      class ListRecordsConfig

        # ------------------------------------------------------------
        # Constants

        DUBLIN_CORE = 'oai_dc'
        private_constant :DUBLIN_CORE

        UNRESERVED_PATTERN = Regexp.new("^[#{URI::RFC2396_REGEXP::PATTERN::UNRESERVED}]+$")
        private_constant :UNRESERVED_PATTERN

        TIME_FORMAT = '%Y-%m-%d'
        private_constant :TIME_FORMAT

        # ------------------------------------------------------------
        # Attributes

        attr_reader :from_time
        attr_reader :until_time
        attr_reader :seconds_granularity
        attr_reader :metadata_prefix
        attr_reader :set

        # ------------------------------------------------------------
        # Initializer

        # Constructs a new +ListRecordsConfig+ with the specified datetime range and metadata prefix.
        # Note that the datetime range must be in UTC.
        #
        # @param from_time [Time, nil] the start (inclusive) of the datestamp range for selective harvesting.
        #   If +from_time+ is omitted, harvesting will extend back to the earliest datestamp in the
        #   repository. (Optional)
        # @param until_time [Time, nil] the end (inclusive) of the datestamp range for selective harvesting.
        #   If +until_time+ is omitted, harvesting will extend forward to the latest datestamp in the
        #   repository. (Optional)
        # @param seconds_granularity [Boolean] whether to include the full time out to the second in
        #   the from / until time range. (Defaults to +false+, i.e., days granularity.)
        # @param metadata_prefix [String, nil] the metadata prefix defining the metadata format requested
        #   from the repository. If +metadata_prefix+ is omitted, the prefix +oai_dc+ (Dublin Core)
        #   will be used.
        # @param set [String, nil] the colon-separated path to the set requested for selective harvesting
        #   from the repository. If +set_spec+ is omitted, harvesting will be across all sets.
        # @raise [RangeError] if +from_time+ is later than +until_time+.
        # @raise [ArgumentError] if +metadata_prefix+ or any +set_spec+ element contains invalid characters,
        #   i.e. URI reserved characters per {https://www.ietf.org/rfc/rfc2396.txt RFC 2396}, or if +from_time+ or
        #   +until_time+ is not in UTC.
        def initialize(from_time: nil, until_time: nil, seconds_granularity: false, metadata_prefix: DUBLIN_CORE, set: nil)
          @from_time, @until_time = valid_range(from_time, until_time)
          @seconds_granularity = seconds_granularity
          @metadata_prefix = valid_prefix(metadata_prefix)
          @set = valid_spec(set)
        end

        # ------------------------------------------------------------
        # Methods

        def to_h
          opts = { metadata_prefix: metadata_prefix }
          (opts[:from] = to_s(from_time)) if from_time
          (opts[:until] = to_s(until_time)) if until_time
          (opts[:set] = set) if set
          opts
        end

        # ------------------------------------------------------------
        # Private methods

        private

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

        def valid_spec(set_spec)
          return nil unless set_spec
          (set_spec.split(':').map do |element|
            if UNRESERVED_PATTERN =~ element
              element
            else
              fail ArgumentError, "setSpec element ''#{element}'' must consist only of RFC 2396 URI unreserved characters"
            end
          end).join(':')
        end

        def valid_prefix(metadata_prefix)
          if UNRESERVED_PATTERN =~ metadata_prefix
            metadata_prefix
          else
            fail ArgumentError, "metadata_prefix ''#{metadata_prefix}'' must consist only of RFC 2396 URI unreserved characters"
          end
        end

        # ------------------------------
        # Conversions

        def to_s(time)
          seconds_granularity ? time : time.strftime(TIME_FORMAT)
        end

      end

    end
  end
end
