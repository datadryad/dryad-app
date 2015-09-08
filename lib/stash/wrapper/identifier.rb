require 'xml/mapping'
require 'ruby-enum'

module Stash
  module Wrapper

    # Identifier type, drawn from the list defined by the DataCite schema.
    class IdentifierType
      include Ruby::Enum

      define :ARK, 'ARK'
      define :DOI, 'DOI'
      define :HANDLE, 'Handle'
      define :URL, 'URL'
    end

    # XML mapping for {IdentifierType}
    class IdentifierTypeNode < ::XML::Mapping::SingleAttributeNode
      def initialize(*args)
        path, *args = super(*args)
        @path = ::XML::XXPath.new(path)
        args
      end

      def extract_attr_value(xml)
        value = default_when_xpath_err { @path.first(xml).text }
        value ? IdentifierType.parse(value) : nil
      end

      def set_attr_value(xml, value)
        @path.first(xml, ensure_created: true).text = value.to_s
      end
    end
    ::XML::Mapping.add_node_class IdentifierTypeNode

    # Typed dataset identifier.
    class Identifier
      include ::XML::Mapping
      identifier_type_node :type, '@type', default_value: nil
      text_node :value, '.', default_value: nil
    end

  end
end
