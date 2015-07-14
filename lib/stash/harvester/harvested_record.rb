module Stash
  module Harvester

    # Abstract superclass of protocol-specific records. Implementations
    # should override {#content} to extract the record content, and may
    # add other protocol-specific attributes as needed.
    #
    # @!attribute [r] identifier
    #   @return [String] a protocol-specific unique identifier for the record.
    # @!attribute [r] timestamp
    #   @return [Time] a timestamp for the record, ideally its time of last modification.
    # @!attribute [r] deleted
    #   @return [Boolean] true if the record has been deleted, false otherwise
    class HarvestedRecord

      attr_reader :identifier
      attr_reader :timestamp
      attr_reader :deleted

      def initialize(identifier:, timestamp:, deleted: false)
        @identifier = identifier
        @timestamp = timestamp
        @deleted = deleted
      end

      # Implementations should override this method to extract the content
      # of the record.
      #
      # @return [String, nil] the content of the record, or +nil+ if the record
      #   has been deleted or the content is otherwise inaccessible.
      def content
        fail "#{self.class} should override #content to fetch the record content, but it doesn't"
      end

      # Visibility modifiers

      private :deleted
      alias_method :deleted?, :deleted
      public :deleted?

    end
  end
end
