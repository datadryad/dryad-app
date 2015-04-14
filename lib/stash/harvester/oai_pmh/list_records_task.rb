module Stash
  module Harvester
    module OAI_PMH

      # Class representing a single harvest (+ListRecords+) operation.
      #
      # @!attribute [r] oai_base_uri
      #   @return [URI] the base URL of the repository.
      # @!attribute [r] opts
      #   @return [Hash] the options passed to the +ListRecords+ verb
      class ListRecordsTask

        # ------------------------------------------------------------
        # Attributes

        attr_reader :oai_base_uri
        attr_reader :opts

        # ------------------------------------------------------------
        # Initializer

        # Creates a new +ListRecordsTask+ for harvesting from the specified OAI-PMH repository, with
        # an optional datetime range and metadata prefix. Note that the datetime range must be in UTC.
        #
        # @param oai_base_url [URI, String] the base URL of the repository. *(Required)*
        # @param config [ListRecordsConfig] The options for the harvest operation. Defaults to
        #   harvesting all records in Dublin Core format.
        # @raise [URI::InvalidURIError] if +oai_base_url+ is a string that is not a valid URI
        def initialize(oai_base_url:, config: ListRecordsConfig.new)
          @oai_base_uri = to_uri(oai_base_url)
          @opts = config.to_h
        end

        # ------------------------------------------------------------
        # Methods

        # @return [Enumerator::Lazy] A lazy enumerator of {OAI_PMH::Record}s
        def list_records
          client = OAI::Client.new @oai_base_uri.to_s
          records = client.list_records(@opts)
          return [].lazy unless records
          full = records.full
          enum = full.lazy.to_enum
          enum.map { |r| Stash::Harvester::OAI_PMH::Record.new(r) }
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
end
