require 'stash/wrapper'

module Stash
  module Wrapper
    class StashWrapperBuilder
      attr_reader :dcs_resource
      attr_reader :uploads

      def initialize(dcs_resource:, uploads:)
        @dcs_resource = dcs_resource
        @uploads = uploads
      end

      def build_stash_wrapper
        StashWrapper.new(
          identifier: to_sw_identifier(dcs_resource.identifier),
          version: Version.new(number: dcs_resource.version, date: Date.today),
          license: to_sw_license(dcs_resource.rights_list),
          inventory: to_sw_inventory(uploads),
          descriptive_elements: [dcs_resource.save_to_xml]
        )
      end

      def build_xml
        build_stash_wrapper.write_xml
      end

      private

      def to_sw_identifier(dcs_identifier)
        return unless dcs_identifier
        raise "Invalid identifier type; expected DOI, was #{dcs_identifier.type}" unless dcs_identifier.type == 'DOI'
        Identifier.new(type: IdentifierType::DOI, value: dcs_identifier.value)
      end

      def to_sw_license(dcs_rights_list)
        return unless dcs_rights_list && !dcs_rights_list.empty?
        dcs_rights = dcs_rights_list[0]
        License.new(name: dcs_rights.value, uri: dcs_rights.uri)
      end

      def to_sw_inventory(uploads)
        return unless uploads && !uploads.empty?
        Inventory.new(files: uploads.map { |upload| to_stash_file(upload) })
      end

      def to_stash_file(upload)
        StashFile.new(
          pathname: upload[:name],
          size_bytes: upload[:size],
          mime_type: upload[:type]
        )
      end
    end
  end
end
