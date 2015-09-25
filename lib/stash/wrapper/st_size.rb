require 'xml/mapping'
require_relative 'st_size_unit_node'

module Stash
  module Wrapper

    class Size
      include ::XML::Mapping

      numeric_node :size, '.'
      size_unit_node :unit, '@unit', default: SizeUnit::BYTE

      def initialize(bytes:)
        self.size = bytes
        self.unit = SizeUnit::BYTE
      end
    end

  end
end
