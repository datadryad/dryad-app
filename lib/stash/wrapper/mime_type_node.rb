require 'xml/mapping'
require 'mime/type'

module Stash
  module Wrapper

# Maps +MIME::Type+ values.
    class MimeTypeNode < ::XML::Mapping::SingleAttributeNode
      def initialize(*args)
        path, *args = super(*args)
        @path = ::XML::XXPath.new(path)
        args
      end

      # Implements +::XML::Mapping::SingleAttributeNode#extract_attr_value+.
      def extract_attr_value(xml)
        mime_type = default_when_xpath_err { @path.first(xml).text }
        return nil unless mime_type
        return mime_type if mime_type.is_a?(MIME::Type)

        mt = MIME::Types[mime_type].first
        return mt if mt

        MIME::Type.new(mime_type)
      end

      # Implements +::XML::Mapping::SingleAttributeNode#set_attr_value+.
      def set_attr_value(xml, value)
        @path.first(xml, ensure_created: true).text = value.to_s
      end
    end

    ::XML::Mapping.add_node_class MimeTypeNode
  end
end
