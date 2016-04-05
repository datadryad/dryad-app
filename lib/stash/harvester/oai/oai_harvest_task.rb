module Stash
  module Harvester
    module OAI

      # Class representing a single OAI-PMH harvest (`ListRecords`) operation.
      #
      class OAIHarvestTask < HarvestTask

        DATE_FORMAT = '%Y-%m-%d'.freeze
        private_constant :DATE_FORMAT

        # Creates a new `ListRecordsTask` for harvesting from the specified OAI-PMH repository, with
        # an optional datetime range and metadata prefix. Note that the datetime range must be in UTC.
        #
        # @param config [OAISourceConfig] The configuration of the OAI data source.
        # @param from_time [Time, nil] the start (inclusive) of the datestamp range for selective harvesting.
        #   If `from_time` is omitted, harvesting will extend back to the earliest datestamp in the
        #   repository. (Optional)
        # @param until_time [Time, nil] the end (inclusive) of the datestamp range for selective harvesting.
        #   If `until_time` is omitted, harvesting will extend forward to the latest datestamp in the
        #   repository. (Optional)
        # @raise [ArgumentError] if `from_time` or `until_time` is not in UTC.
        # @raise [RangeError] if `from_time` is later than `until_time`.
        def initialize(config:, from_time: nil, until_time: nil)
          super
        end

        # Creates a hash containing the {#config} options, {#from_time}, and
        # {#until_time} (if present) formatted appropriately and with appropriate
        # keys to be included in the `ListRecords` request
        #
        # @return [Hash] the options passed to the `ListRecords` verb
        def opts
          opts = config.list_records_opts
          (opts[:from] = to_str(from_time)) if from_time
          (opts[:until] = to_str(until_time)) if until_time
          opts
        end

        # Performs a `ListRecords` operation and returns the result as a
        # lazy enumerator of {OAIRecord}s. Paged responses are transparently
        # fetched one page at a time, as necessary.
        #
        # @return [Enumerator::Lazy<OAIRecord>] A lazy enumerator of the harvested records
        def harvest_records
          do_harvest
        rescue => e
          Stash::Harvester.log.error(e)
          raise e
        end

        def query_uri
          client.send(:build_uri, 'ListRecords', opts)
        end

        private

        def client
          base_uri = config.source_uri
          @client ||= ::OAI::Client.new(base_uri.to_s)
        end

        def to_str(time)
          @config.seconds_granularity ? to_time(time) : to_date(time)
        end

        def do_harvest
          records = list_records
          return [].lazy unless records
          full = records.full
          enum = full.lazy.to_enum
          enum.map { |r| OAIRecord.new(r) }
        end

        def list_records
          client.list_records(opts)
        rescue ::OAI::Exception => e
          raise if e.code != 'noRecordsMatch'
          Stash::Harvester.log.warn("No records returned from #{config.source_uri} for options #{opts}")
          nil
        end

        def to_time(time_or_date)
          if time_or_date.respond_to?(:sec)
            time_or_date
          else
            time = Time.parse(time_or_date.strftime('%Y-%m-%d %H:%M:%S %z')).utc
            Harvester.log.warn("date '#{time_or_date}' converted to time '#{time}' to match configuration seconds_granularity: true")
            time
          end
        end

        def to_date(time_or_date)
          date_str = time_or_date.strftime(DATE_FORMAT)
          Harvester.log.warn("time '#{time_or_date}' converted to date '#{date_str}' to match configuration seconds_granularity: false") if time_or_date.respond_to?(:sec)
          date_str
        end

      end
    end
  end
end
