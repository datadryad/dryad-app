require 'xml/mapping'
require 'ruby-enum'

module Stash
  module Wrapper

    class SizeUnit
      include Ruby::Enum
      
      define :BYTE, 'B'
    end

    # XML mapping for {SizeUnit}
    class SizeUnitNode < ::XML::Mapping::SingleAttributeNode
      def initialize(*args)
        path, *args = super(*args)
        @path = ::XML::XXPath.new(path)
        args
      end

      def extract_attr_value(xml)
        value = default_when_xpath_err { @path.first(xml).text }
        value ? SizeUnit.parse(value) : nil
      end

      def set_attr_value(xml, value)
        @path.first(xml, ensure_created: true).text = value.to_s
      end
    end
    ::XML::Mapping.add_node_class SizeUnitNode

    class Size
      include ::XML::Mapping

      numeric_node :size, '.'
      size_unit_node :unit, '@unit'
    end

    class StashFile
      include ::XML::Mapping

      root_element_name 'file'

      text_node :pathname, 'pathname'
      object_node :size, 'size'
      mime_type_node :mime_type, 'mime_type'
    end


    # File inventory of the dataset submission package.
    class Inventory
      include ::XML::Mapping

      array_node :file, 'file', class: StashFile, default_value: []
      numeric_node :num_files, 'num_files', default_value: 0
    end
  end
end
