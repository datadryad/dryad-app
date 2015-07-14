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
        @source_uri = to_uri(source_url)
      end

      # ------------------------------
      # Conversions

      def to_uri(url)
        (url.is_a? URI) ? url : URI.parse(url)
      end
    end
  end
end
