require 'xml/mapping_extensions'
require_relative 'st_size_unit'

module Stash
  module Wrapper

    # XML mapping for {SizeUnit}
    class SizeUnitNode < ::XML::MappingExtensions::EnumNodeBase
      ENUM_CLASS = SizeUnit
    end
    ::XML::Mapping.add_node_class SizeUnitNode
  end
end
