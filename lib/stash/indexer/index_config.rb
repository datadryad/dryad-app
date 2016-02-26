require 'config/factory'

module Stash
  module Indexer

    # Superclass for configuration of any index.
    #
    # @!attribute [r] uri
    #   @return [URI] the URI of the index
    class IndexConfig
      include ::Config::Factory

      key :adapter

      attr_reader :uri

      # Constructs a new `IndexConfig` with the specified properties.
      #
      # @param url [URI, String] the base URL of the index. *(Required)*
      # @raise [URI::InvalidURIError] if `url` is a string that is not a valid URI
      def initialize(url:)
        @uri = Util.to_uri(url)
      end

      # Constructs a new `Indexer` from this configuration. Implementors should
      # override this method to return an appropriate subclass of `Indexer` for
      # the index.
      #
      # @return [Indexer] an indexer for this index
      def create_indexer
        raise NoMethodError, "#{self.class} should override #create_indexer to create an Indexer, but it doesn't"
      end
    end
  end
end
