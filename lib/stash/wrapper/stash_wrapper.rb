require 'xml/mapping'

require_relative 'descriptive_node'
require_relative 'st_identifier'
require_relative 'stash_administrative'

module Stash
  module Wrapper
    class StashWrapper
      include ::XML::Mapping
      object_node :identifier, 'identifier', class: Identifier
      object_node :stash_administrative, 'stash_administrative', class: StashAdministrative
      descriptive_node :stash_descriptive, 'stash_descriptive'
    end
  end
end
