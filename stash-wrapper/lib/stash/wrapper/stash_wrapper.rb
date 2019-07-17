require 'xml/mapping'

require 'stash/wrapper/descriptive_node'
require 'stash/wrapper/identifier'
require 'stash/wrapper/stash_administrative'

module Stash
  module Wrapper
    # Mapping for the root `<st:stash_wrapper>` element
    class StashWrapper
      include ::XML::MappingExtensions::Namespaced

      namespace ::XML::MappingExtensions::Namespace.new(
        prefix: 'st',
        uri: 'https://dash.ucop.edu/stash_wrapper/',
        schema_location: 'https://dash.ucop.edu/stash_wrapper/stash_wrapper.xsd'
      )

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
      # @param inventory [Inventory, nil] the (optional) file inventory
      # @param descriptive_elements [Array<REXML::Element>] the encapsulated
      #   XML metadata
      def initialize(identifier:, version:, license:, inventory: nil, descriptive_elements:) # rubocop:disable Metrics/ParameterLists
        raise ArgumentError, "identifier does not appear to be an Identifier object: #{identifier || 'nil'}" unless identifier.is_a?(Identifier)

        self.identifier = identifier
        self.stash_administrative = StashAdministrative.new(
          version: version,
          license: license,
          inventory: inventory
        )
        self.stash_descriptive = descriptive_elements
      end

      def id_type
        identifier.type
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

      def inventory
        stash_administrative.inventory
      end

      def file_names
        inv = inventory
        inv ? inv.files.map(&:pathname) : []
      end

      # # Overrides `XML::Mapping#pre_save` to set the XML namespace and schema location.
      # def pre_save(options = { mapping: :_default })
      #   xml = super(options)
      #   xml.add_namespace(NAMESPACE)
      #   xml.add_namespace('xsi', 'http://www.w3.org/2001/XMLSchema-instance')
      #   xml.add_attribute('xsi:schemaLocation', 'https://dash.ucop.edu/stash_wrapper/ https://dash.ucop.edu/stash_wrapper/stash_wrapper.xsd')
      #   xml
      # end
      #
      # # Overrides `XML::Mapping#save_to_xml` to set the XML namespace prefix on all
      # # `stash_wrapper` elements. (The elements in `descriptive_elements` should retain
      # # their existing namespaces and prefixes, if any.)
      # def save_to_xml(options = { mapping: :_default })
      #   xml = super(options)
      #   set_prefix(prefix: NAMESPACE_PREFIX, elem: xml)
      #   xml.add_namespace(nil) # clear the no-prefix namespace
      #   xml.add_namespace(NAMESPACE_PREFIX, NAMESPACE)
      #   xml
      # end
      #
      # private
      #
      # def set_prefix(prefix:, elem:)
      #   return unless elem.namespace == NAMESPACE
      #   # name= with a prefixed name sets namespace by side effect and is the only way to actually output the prefix
      #   elem.name = "#{prefix}:#{elem.name}"
      #   elem.each_element { |e| set_prefix(prefix: prefix, elem: e) }
      # end

    end

  end
end
