module Stash
  module Harvester

    # Superclass for configuration of any index.
    #
    # @!attribute [r] uri
    #   @return [URI] the URI of the index
    class IndexConfig

      attr_reader :uri

      # Constructs a new +IndexConfig+ with the specified properties.
      #
      # @param url [URI, String] the base URL of the index. *(Required)*
      # @raise [URI::InvalidURIError] if +url+ is a string that is not a valid URI
      def initialize(url:)
        @uri = Util.to_uri(url)
      end

      # ------------------------------
      # Class methods

      # Factory method that creates the appropriate {SourceConfig}
      def self.from_hash(hash)
        adapter = hash[:adapter]
        adapter_class = for_adapter(adapter)
        begin
          adapter_params = hash.clone
          adapter_params.delete(:adapter)
          adapter_class.new(adapter_params)
        rescue => e
          raise ArgumentError, "Can't construct configuration class #{adapter_class} for adapter #{adapter}: #{e.message}"
        end
      end

      def self.for_adapter(adapter)
        begin
          adapter = Util.ensure_leading_cap(adapter)
          adapter_class_name = "Stash::Harvester::#{adapter}::#{adapter}IndexConfig"
          Kernel.const_get(adapter_class_name)
        rescue => e
          raise ArgumentError, "Can't find configuration class for adapter '#{adapter}': #{e.message}"
        end
      end

    end
  end
end
