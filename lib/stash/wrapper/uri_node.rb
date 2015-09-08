require 'xml/mapping'

module Stash
  module Wrapper
    # Maps +URI+ objects.
    class UriNode < ::XML::Mapping::SingleAttributeNode
      def initialize(*args)
        path, *args = super(*args)
        @path = ::XML::XXPath.new(path)
        args
      end

      # Implements +::XML::Mapping::SingleAttributeNode#extract_attr_value+.
      def extract_attr_value(xml)
        val = default_when_xpath_err { @path.first(xml).text }
        URI(val.strip)
      end

      # Implements +::XML::Mapping::SingleAttributeNode#set_attr_value+.
      def set_attr_value(xml, value)
        @path.first(xml, ensure_created: true).text = value.to_s
      end
    end

    ::XML::Mapping.add_node_class UriNode
  end
end
