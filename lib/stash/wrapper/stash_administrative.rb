require 'xml/mapping'
require_relative 'st_version'
require_relative 'st_license'
require_relative 'st_embargo'
require_relative 'st_inventory'

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
      # @param embargo [Embargo] the embargo. Note that per the schema,
      #   an `<st:embargo>` element is required even if there is no embargo
      #   on the dataset (in which case it should use {EmbargoType::NONE}).
      # @param inventory [Inventory, nil] the (optional) file inventory
      def initialize(version:, license:, embargo:, inventory: nil)
        self.version = version
        self.license = license
        self.embargo = embargo
        self.inventory = inventory
      end
    end
  end
end
