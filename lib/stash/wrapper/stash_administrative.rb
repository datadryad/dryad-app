require 'xml/mapping'
require 'stash/wrapper/version'
require 'stash/wrapper/license'
require 'stash/wrapper/embargo'
require 'stash/wrapper/inventory'

module Stash
  module Wrapper
    # Mapping for `<st:stash_administrative>`
    class StashAdministrative
      include ::XML::Mapping
      object_node :version, 'version', class: Version
      object_node :license, 'license', class: License
      object_node :embargo, 'embargo', class: Embargo
      object_node :inventory, 'inventory', class: Inventory

      # Creates a new {StashAdministrative}
      #
      # @param version [Version] the version
      # @param license [License] the license
      # @param embargo [Embargo, nil] the embargo information. If no `Embargo`
      #   is supplied, it will default to an embargo of type {EmbargoType::NONE}
      #   with the current date as start and end.
      # @param inventory [Inventory, nil] the (optional) file inventory
      def initialize(version:, license:, embargo: nil, inventory: nil)
        fail ArgumentError, "version does not appear to be a Version object: #{version || 'nil'}" unless version.is_a?(Version)
        fail ArgumentError, "license does not appear to be a License object: #{license || 'nil'}" unless license.is_a?(License)
        fail ArgumentError, "embargo does not appear to be an Embargo object: #{embargo || 'nil'}" if embargo unless embargo.is_a?(Embargo)
        fail ArgumentError, "inventory does not appear to be an Inventory object: #{inventory || 'nil'}" if inventory unless inventory.is_a?(Inventory)

        self.version = version
        self.license = license
        self.embargo = embargo || Embargo.none
        self.inventory = inventory
      end
    end
  end
end
