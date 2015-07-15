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
      # Class methods

      # Parses the specified YAML string and passes it as a hash
      # with symbol keys to the implementation class initializer
      #
      # @return [SourceConfig] a new instance of this implementation class
      def self.from_yaml(yml)
        params = YAML.load(yml).map { |k, v| [k.to_sym, v] }.to_h
        new(params)
      end

      # ------------------------------
      # Private methods

      private

      def to_uri(url)
        (url.is_a? URI) ? url : URI.parse(url)
      end

    end
  end
end
