require 'yaml'
require_relative '../source_config'

module Stash
  module Harvester
    module OAI

      # The configuration of an OAI data source. Defaults to harvesting Dublin Core at seconds
      # granularity, across all record sets.
      #
      # @!attribute [r] metadata_prefix
      #   @return [String] the metadata prefix defining the metadata format requested from the repository.
      # @!attribute [r] set
      #   @return [String, nil] the colon-separated path to the set requested for selective harvesting.
      # @!attribute seconds_granularity [r]
      #   @return [Boolean] whether to include the full time out to the second in the from / until time range. (Defaults to false, i.e., days granularity.)
      class OAISourceConfig < SourceConfig

        # ------------------------------------------------------------
        # Config::Factory

        protocol 'OAI'

        DUBLIN_CORE = 'oai_dc'.freeze
        private_constant :DUBLIN_CORE

        UNRESERVED_PATTERN = Regexp.new("^[#{URI::RFC2396_REGEXP::PATTERN::UNRESERVED}]+$")
        private_constant :UNRESERVED_PATTERN

        attr_reader :seconds_granularity
        attr_reader :metadata_prefix
        attr_reader :set

        # Constructs a new {OAISourceConfig} with the specified properties.
        #
        # @param oai_base_url [URI, String] the base URL of the repository. *(Required)*
        # @param metadata_prefix [String, nil] the metadata prefix defining the metadata format requested
        #   from the repository. If `metadata_prefix` is omitted, the prefix `oai_dc` (Dublin Core)
        #   will be used.
        # @param set [String, nil] the colon-separated path to the set requested for selective harvesting
        #   from the repository. If `set_spec` is omitted, harvesting will be across all sets.
        # @param seconds_granularity [Boolean] whether to include the full time out to the second in
        #   the from / until time range. (Defaults to `false`, i.e., days granularity.)
        # @raise [URI::InvalidURIError] if `oai_base_url` is a string that is not a valid URI
        # @raise [ArgumentError] if `metadata_prefix` or any `set_spec` element contains invalid characters,
        #   i.e. URI reserved characters per [RFC 2396](https://www.ietf.org/rfc/rfc2396.txt)
        def initialize(oai_base_url:, metadata_prefix: DUBLIN_CORE, set: nil, seconds_granularity: false)
          super(source_url: oai_base_url)
          @seconds_granularity = seconds_granularity
          @metadata_prefix = valid_prefix(metadata_prefix)
          @set = valid_spec(set)
        end

        def list_records_opts
          opts = { metadata_prefix: metadata_prefix }
          (opts[:set] = set) if set
          opts
        end

        def create_harvest_task(from_time: nil, until_time: nil)
          OAIHarvestTask.new(config: self, from_time: from_time, until_time: until_time)
        end

        private

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

      end

    end
  end
end
