require 'xml/mapping'

module Stash
  module Wrapper
    # XML mapping for XML Schema dates.
    # Known limitation: loses time zone info
    class DateNode < ::XML::Mapping::SingleAttributeNode
      def initialize(*args)
        path, *args = super(*args)
        @path = ::XML::XXPath.new(path)
        args
      end

      def extract_attr_value(xml)
        value = default_when_xpath_err { @path.first(xml).text }
        value ? Date.xmlschema(value).utc : nil
      end

      def set_attr_value(xml, value)
        @path.first(xml, ensure_created: true).text = value.xmlschema
      end
    end
    ::XML::Mapping.add_node_class DateNode
  end
end
