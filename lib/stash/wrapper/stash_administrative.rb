require 'xml/mapping'
require_relative 'version'
require_relative 'license'
require_relative 'embargo'
require_relative 'inventory'

module Stash
  module Wrapper
    class StashAdministrative
      include ::XML::Mapping
      object_node :version, 'version', class: Version
      object_node :license, 'license', class: License
      object_node :embargo, 'embargo', class: Embargo
      object_node :inventory, 'inventory', class: Inventory
    end
  end
end
