require 'xml/mapping'

module Stash
  module Wrapper

    # Node class for `<st:stash_descriptive>` elements.
    class DescriptiveNode < XML::Mapping::SingleAttributeNode

      # See `XML::Mapping::SingleAttributeNode#initialize`
      def initialize(*args)
        path, *myargs = super(*args)
        @path = ::XML::XXPath.new(path)
        myargs # rubocop:disable Lint/Void
      end

      # Extracts the children of this element as an array.
      # @param xml [REXML::Element] this `<st:stash_descriptive>` element
      # @return [Array<REXML::Element>] the child elements
      def extract_attr_value(xml)
        default_when_xpath_err { @path.first(xml).elements.to_a }
      end

      # Sets the array of elements representetd by this node
      # as the children of the corresponding `<st:stash_descriptive>`
      # element.
      # @param xml [REXML::Element] this element
      # @param value [Array<REXML::Element>] the child elements
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
