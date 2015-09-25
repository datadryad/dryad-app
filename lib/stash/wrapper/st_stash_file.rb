require 'xml/mapping'
require 'xml/mapping_extensions'

module Stash
  module Wrapper
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
  end
end
