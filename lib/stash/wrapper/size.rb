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
        self.size = bytes
        self.unit = SizeUnit::BYTE
      end
    end

  end
end
