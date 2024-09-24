module StashEngine
  module LandingHelper
    # From https://stackoverflow.com/a/33011519
    class SniffColSeparator
      DELIMITERS = [',', ';', "\t", '|', ':'].freeze

      def initialize(string:)
        @string = string
      end

      def self.find(string)
        new(string: string).find
      end

      def find
        # String empty
        return nil unless first

        # No separator found
        return nil unless valid?

        delimiters.first.first
      end

      private

      def valid?
        !delimiters.collect(&:last).reduce(:+).zero?
      end

      def delimiters
        @delimiters ||= DELIMITERS.inject({}, &count).sort(&most_found)
      end

      def most_found
        ->(a, b) { b[1] <=> a[1] }
      end

      def count
        ->(hash, delimiter) {
          hash[delimiter] = first.count(delimiter)
          hash
        }
      end

      def first
        @first ||= @string.split("\n").first
      end
    end
  end
end
