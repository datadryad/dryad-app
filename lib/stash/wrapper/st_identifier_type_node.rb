require 'xml/mapping_extensions'
require_relative 'st_identifier_type'

module Stash
  module Wrapper
    # XML mapping for {IdentifierType}
    class IdentifierTypeNode < ::XML::MappingExtensions::EnumNodeBase
      ENUM_CLASS = IdentifierType
    end
    ::XML::Mapping.add_node_class IdentifierTypeNode
  end
end
