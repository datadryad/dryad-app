require 'xml/mapping'
require_relative 'st_identifier'
require_relative 'stash_administrative'
require_relative 'stash_descriptive'

module Stash
  module Wrapper
    class StashWrapper
      include ::XML::Mapping
      object_node :identifier, 'identifier', class: Identifier
      object_node :stash_administrative, 'stash_administrative', class: StashAdministrative
      object_node :stash_descriptive, 'stash_descriptive', class: StashDescriptive
    end
  end
end
