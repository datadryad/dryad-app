require 'stash/wrapper'
require 'stash/repo/file_builder'

module Stash
  module Merritt
    module Builders
      class StashWrapperBuilder < Stash::Repo::ValidatingXMLBuilder
        include Stash::Wrapper

        class << self
          def stash_wrapper_schema
            @stash_wrapper_schema ||= begin
              schema_file = File.dirname(__FILE__) + '/schemas/stash-wrapper.xsd'
              Nokogiri::XML::Schema(File.open(schema_file))
            end
          end
        end

        attr_reader :dcs_resource
        attr_reader :uploads
        attr_reader :version_number

        def initialize(dcs_resource:, version_number:, uploads:)
          super(file_name: 'stash-wrapper.xml')
          @dcs_resource = dcs_resource
          @version_number = version_number
          @uploads = uploads
        end

        def mime_type
          MIME::Types['text/xml'].first
        end

        def build_xml
          StashWrapper.new(
            identifier: to_sw_identifier(dcs_resource.identifier),
            version: Version.new(number: version_number, date: Date.today),
            license: to_sw_license(dcs_resource.rights_list),
            inventory: to_sw_inventory(uploads),
            descriptive_elements: [dcs_resource.save_to_xml]
          ).write_xml
        end

        def schema
          StashWrapperBuilder.stash_wrapper_schema
        end

        private

        def date_or_nil(embargo_end_date)
          return unless embargo_end_date
          return embargo_end_date if embargo_end_date.is_a?(Date)
          return embargo_end_date.utc.to_date if embargo_end_date.respond_to?(:utc)
          raise ArgumentError, "Specified end date #{embargo_end_date} does not appear to be a date or time"
        end

        def to_sw_embargo(embargo_end_date)
          return unless embargo_end_date
          start_date = default_start_date(embargo_end_date)
          Embargo.new(type: EmbargoType::DOWNLOAD, period: EmbargoType::NONE.value, start_date: start_date, end_date: embargo_end_date)
        end

        def default_start_date(embargo_end_date)
          start_date = Date.today
          return start_date if start_date < embargo_end_date
          embargo_end_date
        end

        def to_sw_identifier(dcs_identifier)
          return unless dcs_identifier
          raise "Invalid identifier type; expected DOI, was #{dcs_identifier.identifier_type}" unless dcs_identifier.identifier_type == 'DOI'
          Identifier.new(type: IdentifierType::DOI, value: dcs_identifier.value)
        end

        def to_sw_license(dcs_rights_list)
          return unless dcs_rights_list && !dcs_rights_list.empty?
          dcs_rights = dcs_rights_list[0]
          License.new(name: dcs_rights.value, uri: dcs_rights.uri)
        end

        def to_sw_inventory(uploads)
          return unless uploads
          Inventory.new(files: uploads.map { |upload| to_stash_file(upload) })
        end

        def to_stash_file(upload)
          StashFile.new(
            pathname: upload.upload_file_name,
            size_bytes: upload.upload_file_size,
            mime_type: upload.upload_content_type
          )
        end
      end
    end
  end
end
