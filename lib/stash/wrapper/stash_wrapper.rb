require 'xml/mapping'

require_relative 'descriptive_node'
require_relative 'identifier'
require_relative 'stash_administrative'

module Stash
  module Wrapper
    # Mapping for the root `<st:stash_wrapper>` element
    class StashWrapper
      include ::XML::Mapping

      # The `stash_wrapper` namespace
      NAMESPACE = 'http://dash.cdlib.org/stash_wrapper/'

      # The `st` prefix for the `stash_wrapper` namespace
      NAMESPACE_PREFIX = 'st'

      root_element_name 'stash_wrapper'

      object_node :identifier, 'identifier', class: Identifier
      object_node :stash_administrative, 'stash_administrative', class: StashAdministrative
      descriptive_node :stash_descriptive, 'stash_descriptive'

      # Creates a new {StashWrapper}. As a convenience, constructs an
      # internal {StashAdministrative} directly from the supplied
      # administrative elements.
      #
      # @param identifier [Identifier] the identifier
      # @param version [Version] the version
      # @param license [License] the license
      # @param embargo [Embargo, nil] the embargo information. If no `Embargo`
      #   is supplied, it will default to an embargo of type {EmbargoType::NONE}
      #   with the current date as start and end.
      # @param inventory [Inventory, nil] the (optional) file inventory
      # @param descriptive_elements [Array<REXML::Element>] the encapsulated
      #   XML metadata
      def initialize(identifier:, version:, license:, embargo: nil, inventory: nil, descriptive_elements:) # rubocop:disable Metrics/ParameterLists
        self.identifier = identifier
        self.stash_administrative = StashAdministrative.new(
          version: version,
          license: license,
          embargo: embargo,
          inventory: inventory
        )
        self.stash_descriptive = descriptive_elements
      end

      def id_value
        identifier.value
      end

      def version
        stash_administrative.version
      end

      def version_number
        version.version_number
      end

      def version_date
        version.date
      end

      def license
        stash_administrative.license
      end

      def license_name
        license.name
      end

      def license_uri
        license.uri
      end

      def embargo
        stash_administrative.embargo
      end

      def embargo_type
        embargo.type
      end

      def embargo_end_date
        embargo.end_date
      end

      def inventory
        stash_administrative.inventory
      end

      # Overrides `XML::Mapping#pre_save` to set the XML namespace and schema location.
      def pre_save(options = { mapping: :_default })
        xml = super(options)
        xml.add_namespace(NAMESPACE)
        xml.add_namespace('xsi', 'http://www.w3.org/2001/XMLSchema-instance')
        xml.add_attribute('xsi:schemaLocation', 'http://dash.cdlib.org/stash_wrapper/ http://dash.cdlib.org/stash_wrapper/stash_wrapper.xsd')
        xml
      end

      # Overrides `XML::Mapping#save_to_xml` to set the XML namespace prefix on all
      # `stash_wrapper` elements. (The elements in `descriptive_elements` should retain
      # their existing namespaces and prefixes, if any.)
      def save_to_xml(options = { mapping: :_default })
        elem = super(options)
        set_prefix(prefix: NAMESPACE_PREFIX, elem: elem)
        elem.add_namespace(nil) # clear the no-prefix namespace
        elem.add_namespace(NAMESPACE_PREFIX, NAMESPACE)
        elem
      end

      def self.parse_xml(xml_str)
        xml = REXML::Document.new(xml_str).root
        load_from_xml(xml)
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
