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
        self.version = valid_version(version)
        self.license = valid_license(license)
        self.embargo = valid_embargo(embargo)
        self.inventory = valid_inventory_or_nil(inventory)
      end

      private

      def valid_version(version)
        return version if version.is_a?(Version)
        raise ArgumentError, "version does not appear to be a Version object: #{version || 'nil'}"
      end

      def valid_license(license)
        return license if license.is_a?(License)
        raise ArgumentError, "license does not appear to be a License object: #{license || 'nil'}"
      end

      def valid_embargo(embargo)
        return Embargo.none unless embargo
        return embargo if embargo.is_a?(Embargo)
        raise ArgumentError, "embargo does not appear to be an Embargo object: #{embargo.inspect}"
      end

      def valid_inventory_or_nil(inventory)
        return unless inventory
        return inventory if inventory.is_a?(Inventory)
        raise ArgumentError, "inventory does not appear to be an Inventory object: #{inventory || 'nil'}"
      end

    end
  end
end
