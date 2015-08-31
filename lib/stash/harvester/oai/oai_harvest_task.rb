module Stash
  module Harvester
    module OAI

      # TODO: check for documentation of inherited attributes

      # Class representing a single OAI-PMH harvest (+ListRecords+) operation.
      #
      class OAIHarvestTask < HarvestTask

        # ------------------------------------------------------------
        # Constants

        TIME_FORMAT = '%Y-%m-%d'
        private_constant :TIME_FORMAT

        # ------------------------------------------------------------
        # Initializer

        # Creates a new +ListRecordsTask+ for harvesting from the specified OAI-PMH repository, with
        # an optional datetime range and metadata prefix. Note that the datetime range must be in UTC.
        #
        # @param config [OAISourceConfig] The configuration of the OAI data source.
        # @param from_time [Time, nil] the start (inclusive) of the datestamp range for selective harvesting.
        #   If +from_time+ is omitted, harvesting will extend back to the earliest datestamp in the
        #   repository. (Optional)
        # @param until_time [Time, nil] the end (inclusive) of the datestamp range for selective harvesting.
        #   If +until_time+ is omitted, harvesting will extend forward to the latest datestamp in the
        #   repository. (Optional)
        # @raise [ArgumentError] if +from_time+ or +until_time+ is not in UTC.
        # @raise [RangeError] if +from_time+ is later than +until_time+.
        def initialize(config:, from_time: nil, until_time: nil)
          super
        end

        # ------------------------------------------------------------
        # Methods

        # Creates a hash containing the {#config} options, {#from_time}, and
        # {#until_time} (if present) formatted appropriately and with appropriate
        # keys to be included in the +ListRecords+ request
        #
        # @return [Hash] the options passed to the +ListRecords+ verb
        def opts
          opts = config.to_h
          (opts[:from] = to_s(from_time)) if from_time
          (opts[:until] = to_s(until_time)) if until_time
          opts
        end

        # Performs a +ListRecords+ operation and returns the result as a
        # lazy enumerator of {OAIRecord}s. Paged responses are transparently
        # fetched one page at a time, as necessary.
        #
        # @return [Enumerator::Lazy<OAIRecord>] A lazy enumerator of the harvested records
        def harvest_records
          base_uri = config.source_uri
          client = ::OAI::Client.new(base_uri.to_s)
          records = client.list_records(opts)
          return [].lazy unless records
          full = records.full
          enum = full.lazy.to_enum
          enum.map { |r| OAIRecord.new(r) }
        end

        # ------------------------------------------------------------
        # Private methods

        private

        # ------------------------------
        # Conversions

        def to_s(time)
          @config.seconds_granularity ? time : time.strftime(TIME_FORMAT)
        end

      end
    end
  end
end
