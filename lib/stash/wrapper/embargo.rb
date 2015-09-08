require 'xml/mapping'
require 'ruby-enum'
require_relative 'date_node'

module Stash
  module Wrapper
    
    class EmbargoType
      include Ruby::Enum

      define :NONE, 'none'
      define :DOWNLOAD, 'download'
      define :DESCRIPTION, 'description'
    end

    # XML mapping for {EmbargoType}
    class EmbargoTypeNode < ::XML::Mapping::SingleAttributeNode
      def initialize(*args)
        path, *args = super(*args)
        @path = ::XML::XXPath.new(path)
        args
      end

      def extract_attr_value(xml)
        value = default_when_xpath_err { @path.first(xml).text }
        value ? EmbargoType.parse(value) : nil
      end

      def set_attr_value(xml, value)
        @path.first(xml, ensure_created: true).text = value.to_s
      end
    end
    ::XML::Mapping.add_node_class EmbargoTypeNode
    
    # Dataset embargo.
    class Embargo
      include ::XML::Mapping
      embargo_type_node :type, 'type'
      text_node :period, 'period'
      date_node :start, 'start'
      date_node :end, 'end'
    end
  end
end
