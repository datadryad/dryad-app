module Stash
  module Harvester

    # Superclass for configuration of any data source.
    #
    # @!attribute [r] source_uri
    #   @return [URI] the base URL of the repository.
    class SourceConfig

      attr_reader :source_uri

      # Constructs a new +SourceConfig+ with the specified properties.
      #
      # @param source_url [URI, String] the base URL of the repository. *(Required)*
      # @raise [URI::InvalidURIError] if +source_url+ is a string that is not a valid URI
      def initialize(source_url:)
        @source_uri = Util.to_uri(source_url)
      end

      # ------------------------------
      # Class methods

      # Factory method that creates the appropriate {SourceConfig}
      def self.from_hash(hash)
        protocol = hash[:protocol]
        protocol_class = for_protocol(protocol)
        begin
          protocol_params = hash.clone
          protocol_params.delete(:protocol)
          protocol_class.new(protocol_params)
        rescue => e
          raise ArgumentError, "Can't construct configuration class #{protocol_class} for protocol #{protocol}: #{e.message}"
        end
      end

      def self.for_protocol(protocol)
        protocol = Util.ensure_leading_cap(protocol)
        protocol_class_name = "Stash::Harvester::#{protocol}::#{protocol}SourceConfig"
        Kernel.const_get(protocol_class_name)
      rescue => e
        raise ArgumentError, "Can't find configuration class for protocol '#{protocol}': #{e.message}"
      end

    end
  end
end
