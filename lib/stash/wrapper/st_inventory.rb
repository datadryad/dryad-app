require 'xml/mapping'
require 'xml/mapping_extensions'
require 'ruby-enum'

module Stash
  module Wrapper

    class SizeUnit
      include Ruby::Enum

      define :BYTE, 'B'
    end

    # XML mapping for {SizeUnit}
    class SizeUnitNode < ::XML::MappingExtensions::EnumNodeBase
      ENUM_CLASS = SizeUnit
    end
    ::XML::Mapping.add_node_class SizeUnitNode

    class Size
      include ::XML::Mapping

      numeric_node :size, '.'
      size_unit_node :unit, '@unit', default: 'B'

      def initialize(bytes:)
        self.size = bytes
        self.unit = 'B'
      end
    end

    class StashFile
      include ::XML::Mapping

      root_element_name 'file'

      text_node :pathname, 'pathname'
      object_node :size, 'size'
      mime_type_node :mime_type, 'mime_type'

      def initialize(pathname:, size_bytes:, mime_type:)
        self.pathname = pathname
        self.size_bytes = size_bytes
        self.mime_type = mime_type
      end

      def mime_type=(value)
        @mime_type = to_mime_type(value)
      end

      def size_bytes=(bytes)
        self.size = Size.new(bytes: bytes)
      end

      def size_bytes
        size.size
      end

      private

      def to_mime_type(value)
        return nil unless value
        return value if value.is_a?(MIME::Type)
        mt_string = value.to_s
        (mt = MIME::Types[mt_string].first) ? mt : MIME::Type.new(mt_string)
      end
    end

    # File inventory of the dataset submission package.
    class Inventory
      include ::XML::Mapping

      array_node :files, 'file', class: StashFile, default_value: []
      numeric_node :num_files, '@num_files', default_value: 0

      def initialize(files:)
        self.files = files
        self.num_files = files.size
      end
    end
  end
end
