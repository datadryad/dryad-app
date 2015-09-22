require 'xml/mapping'

module Stash
  module Wrapper
    class DescriptiveNode < XML::Mapping::SingleAttributeNode

      # See `XML::Mapping::SingleAttributeNode#initialize`
      def initialize(*args)
        path, *args = super(*args)
        @path = ::XML::XXPath.new(path)
        args
      end

      def extract_attr_value(xml)
        default_when_xpath_err { @path.first(xml).elements.to_a }
      end

      def set_attr_value(xml, value)
        parent = @path.first(xml, ensure_created: true)
        value.each do |child|
          parent.elements.add(child)
        end
      end

    end
    XML::Mapping.add_node_class DescriptiveNode
  end
end
