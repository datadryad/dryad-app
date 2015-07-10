module Stash
  module Harvester
    class HarvestedRecord

      attr_reader :identifier
      attr_reader :timestamp
      attr_reader :deleted

      def initialize(identifier:, timestamp:, deleted: false)
        @identifier = identifier
        @timestamp = timestamp
        @deleted = deleted
      end

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
