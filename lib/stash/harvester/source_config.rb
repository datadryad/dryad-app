module Stash
  module Harvester

    # Superclass for configuration of any data source.
    #
    # @!attribute [r] source_uri
    #   @return [URI] the base URL of the repository.
    class SourceConfig < ConfigBase

      CONFIG_KEY = :protocol

      attr_reader :source_uri

      # Constructs a new +SourceConfig+ with the specified properties.
      #
      # @param source_url [URI, String] the base URL of the repository. *(Required)*
      # @raise [URI::InvalidURIError] if +source_url+ is a string that is not a valid URI
      def initialize(source_url:)
        @source_uri = Util.to_uri(source_url)
      end
    end
  end
end
