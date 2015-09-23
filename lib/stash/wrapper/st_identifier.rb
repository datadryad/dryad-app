require 'xml/mapping'
require 'xml/mapping_extensions'
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
    class IdentifierTypeNode < ::XML::MappingExtensions::EnumNodeBase
      ENUM_CLASS = IdentifierType
    end
    ::XML::Mapping.add_node_class IdentifierTypeNode

    # Typed dataset identifier.
    class Identifier
      include ::XML::Mapping
      identifier_type_node :type, '@type', default_value: nil
      text_node :value, '.', default_value: nil

      def initialize(type:, value:)
        self.type = type
        self.value = value
      end
    end

  end
end
