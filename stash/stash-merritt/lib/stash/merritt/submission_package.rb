require 'stash/merritt/builders'

module Stash
  module Merritt
    class SubmissionPackage
      include Builders

      attr_reader :resource, :packaging

      # @param resource [StashEngine::Resource]
      # @param packaging [Stash::Sword::Packaging]
      def initialize(resource:, packaging:)
        raise ArgumentError, 'No resource provided' unless resource
        raise ArgumentError, "Resource (#{resource.id}) must have an identifier before submission" unless resource.identifier_str

        @resource = resource
        @packaging = packaging
      end

      # @return [String] the path to the payload file
      def payload
        raise NoMethodError, "#{self.class} should override #packaging to return the payload, but it doesn't"
      end

      def dc4_xml
        @dc4_xml ||= dc4_builder.contents
      end

      def dc4_builder
        @dc4_builder ||= begin
          datacite_xml_factory = Datacite::Mapping::DataciteXMLFactory.new(
            doi_value: resource.identifier_value,
            se_resource_id: resource_id,
            total_size_bytes: total_size_bytes,
            version: version_number
          )
          MerrittDataciteBuilder.new(datacite_xml_factory)
        end
      end

      def resource_id
        resource.id
      end

      def resource_title
        resource.title
      end

      def total_size_bytes
        @total_size_bytes ||= uploads.inject(0) do |sum, u|
          upload_file_size = u.upload_file_size
          upload_file_size ? sum + upload_file_size : sum
        end
      end

      def version_number
        @version_number ||= resource.version_number
      end

      def dc4_resource
        @dc4_resource ||= Datacite::Mapping::Resource.parse_xml(dc4_xml)
      end

      def uploads
        resource.current_file_uploads
      end

      def new_uploads
        resource.new_data_files.reject { |upload| upload.file_state == 'deleted' }
      end

      def builders
        @builders ||= [
          StashWrapperBuilder.new(dcs_resource: dc4_resource, version_number: version_number, uploads: uploads),
          dc4_builder,
          MerrittOAIDCBuilder.new(resource_id: resource_id),
          DataONEManifestBuilder.new(new_uploads),
          MerrittDeleteBuilder.new(resource_id: resource_id)
        ]
      end
    end
  end
end
