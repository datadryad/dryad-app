require 'xml/mapping'
require_relative 'size_unit_node'

module Stash
  module Wrapper

    # Mapping for `<st:size>`
    class Size
      include ::XML::Mapping

      numeric_node :size, '.'
      size_unit_node :unit, '@unit', default: SizeUnit::BYTE

      # Creates a new {Size}
      # @param bytes [Integer] the size in bytes
      def initialize(bytes:)
        self.size = bytes
        self.unit = SizeUnit::BYTE
      end
    end

  end
end
