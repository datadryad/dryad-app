require 'xml/mapping'
require 'stash/wrapper/size_unit'

module Stash
  module Wrapper

    # Mapping for `<st:size>`
    class Size
      include ::XML::Mapping

      numeric_node :size, '.'
      typesafe_enum_node :unit, '@unit', class: SizeUnit, default: SizeUnit::BYTE

      # Creates a new {Size}
      # @param bytes [Integer] the size in bytes
      def initialize(bytes:)
        self.size = valid_size(bytes)
        self.unit = SizeUnit::BYTE
      end

      private

      def valid_size(bytes)
        return bytes if bytes && bytes.respond_to?(:to_i) && bytes == bytes.to_i

        raise ArgumentError, "specified file size does not appear to be an integer byte count: #{bytes || 'nil'}"
      end
    end

  end
end
