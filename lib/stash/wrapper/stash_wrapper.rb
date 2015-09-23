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

      def initialize(identifier:, version:, license:, embargo:, inventory:, descriptive_elements:)
        self.identifier = identifier
        self.stash_administrative = StashAdministrative.new(
            version: version,
            license: license,
            embargo: embargo,
            inventory: inventory
        )
        self.stash_descriptive = descriptive_elements
      end

    end
  end
end
