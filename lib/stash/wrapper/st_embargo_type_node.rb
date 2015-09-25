require 'xml/mapping_extensions'
require_relative 'st_embargo_type'

module Stash
  module Wrapper
    # XML mapping for {EmbargoType}
    class EmbargoTypeNode < ::XML::MappingExtensions::EnumNodeBase
      ENUM_CLASS = EmbargoType
    end
    ::XML::Mapping.add_node_class EmbargoTypeNode
  end
end


