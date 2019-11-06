require 'xml/mapping'
require 'xml/mapping_extensions'

module Stash
  module Wrapper
    # Mapping for `<st:version>`
    class Version
      include ::XML::Mapping
      numeric_node :version_number, 'version_number'
      date_node :date, 'date', zulu: true
      text_node :note, 'note', default_value: nil

      # Creates a new {Version}
      # @param number [Integer] the version number
      # @param date [Date] the date the new version was created
      # @param note [String, nil] the (optional) version note
      def initialize(number:, date:, note: nil)
        self.version_number = valid_number(number)
        self.date = valid_date(date)
        self.note = note
      end

      private

      def valid_number(number)
        return number if number && number.respond_to?(:to_i) && number == number.to_i
        raise ArgumentError, "specified version number does not appear to be an integer: #{number || 'nil'}"
      end

      def valid_date(date)
        return date if date.respond_to?(:iso8601)
        raise ArgumentError, "date does not appear to be a Date object: #{date || 'nil'}"
      end

    end
  end
end
