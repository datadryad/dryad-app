module Stash
  module Harvester

    # Superclass for configuration of any index.
    #
    # @!attribute [r] uri
    #   @return [URI] the URI of the index
    class IndexConfig < ConfigBase

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

      def self.config_key
        :adapter
      end

      # TODO: figure out how to pull this up
      def self.config_class_name(namespace)
        "Stash::Harvester::#{namespace}::#{namespace}IndexConfig"
      end

      # TODO: inline this
      def self.for_adapter(adapter)
        for_namespace(adapter)
      end

    end
  end
end
