require 'xml/mapping'
require 'xml/mapping_extensions'

module Stash
  module Wrapper
    # Mapping for `<st:file>`.
    class StashFile
      include ::XML::Mapping

      root_element_name 'file'

      text_node :pathname, 'pathname'
      object_node :size, 'size'
      mime_type_node :mime_type, 'mime_type'

      # Creates a new {StashFile} object
      #
      # @param pathname [String] the pathname
      # @param size_bytes [Integer] the size in bytes
      # @param mime_type [MIME::Type, String] the MIME type, as either a
      #   `MIME::Type` object or a string
      def initialize(pathname:, size_bytes:, mime_type:)
        self.pathname = pathname
        self.size_bytes = size_bytes
        self.mime_type = mime_type
      end

      # Sets the MIME type, converting from a string if necessary
      # @param value [MIME::Type, String] the MIME type, as either a
      #   `MIME::Type` object or a string
      def mime_type=(value)
        @mime_type = to_mime_type(value)
      end

      # Sets the size in bytes, expanding it to a {Size} object
      # @param bytes [Integer] the size in bytes
      def size_bytes=(bytes)
        self.size = Size.new(bytes: bytes)
      end

      # Gets the size in bytes, extracting it from the {Size}
      # @return [Integer] the size in bytes
      def size_bytes
        size.size
      end

      private

      def to_mime_type(value)
        return MIME::Type.new('application/octet-stream') unless value.present?
        return value if value.is_a?(MIME::Type)

        mt_string = value.to_s
        (mt = MIME::Types[mt_string].first) ? mt : MIME::Type.new(mt_string)
      end
    end
  end
end
