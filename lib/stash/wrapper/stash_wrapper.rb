require 'xml/mapping'

require_relative 'descriptive_node'
require_relative 'st_identifier'
require_relative 'stash_administrative'

module Stash
  module Wrapper
    class StashWrapper
      include ::XML::Mapping

      NAMESPACE = 'http://dash.cdlib.org/stash_wrapper/'
      NAMESPACE_PREFIX = 'st'

      root_element_name 'stash_wrapper'

      object_node :identifier, 'identifier', class: Identifier
      object_node :stash_administrative, 'stash_administrative', class: StashAdministrative
      descriptive_node :stash_descriptive, 'stash_descriptive'

      def initialize(identifier:, version:, license:, embargo:, inventory:, descriptive_elements:) # rubocop:disable Metrics/ParameterLists
        self.identifier = identifier
        self.stash_administrative = StashAdministrative.new(
          version: version,
          license: license,
          embargo: embargo,
          inventory: inventory
        )
        self.stash_descriptive = descriptive_elements
      end

      def pre_save(options = { mapping: :_default })
        xml = super(options)
        xml.add_namespace(NAMESPACE)
        xml.add_namespace('xsi', 'http://www.w3.org/2001/XMLSchema-instance')
        xml.add_attribute('xsi:schemaLocation', 'http://dash.cdlib.org/stash_wrapper/ http://dash.cdlib.org/stash_wrapper/stash_wrapper.xsd')
        xml
      end

      def save_to_xml(options = { mapping: :_default })
        elem = super(options)
        set_prefix(prefix: NAMESPACE_PREFIX, elem: elem)
        elem.add_namespace(nil) # clear the no-prefix namespace
        elem.add_namespace(NAMESPACE_PREFIX, NAMESPACE)
        elem
      end

      private

      def set_prefix(prefix:, elem:)
        return unless elem.namespace == NAMESPACE

        # name= with a prefixed name sets namespace by side effect and is the only way to actually output the prefix
        elem.name = "#{prefix}:#{elem.name}"
        elem.each_element { |e| set_prefix(prefix: prefix, elem: e) }
      end

    end

  end
end
