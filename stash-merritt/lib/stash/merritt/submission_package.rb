module Stash
  module Merritt
    module SubmissionPackage
      Dir.glob(File.expand_path('../submission_package/*.rb', __FILE__)).sort.each(&method(:require))

      def resource
        raise NoMethodError, "#{self.class} should override #resource to return the resource, but it doesn't"
      end

      def resource_id
        resource.id
      end

      def resource_title
        @resource_title = begin
          primary_title = resource.titles.where(title_type: nil).first
          primary_title.title.to_s if primary_title
        end
      end

      def datacite_xml_factory
        @datacite_xml_factory ||= Datacite::Mapping::DataciteXMLFactory.new(doi_value: resource.identifier_value, se_resource_id: resource_id, total_size_bytes: total_size_bytes, version: version_number)
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
        @dc4_resource ||= datacite_xml_factory.build_resource
      end

      def uploads
        resource.current_file_uploads
      end

      def embargo_end_date
        @embargo_end_date ||= (embargo = resource.embargo) && embargo.end_date
      end

      def new_uploads
        resource.new_file_uploads.select { |upload| upload.file_state != 'deleted' }
      end

      def builders # rubocop:disable Metrics/AbcSize
        @builders ||= [
          StashWrapperBuilder.new(dcs_resource: dc4_resource, version_number: version_number, uploads: uploads, embargo_end_date: embargo_end_date),
          MerrittDataciteBuilder.new(datacite_xml_factory),
          MerrittOAIDCBuilder.new(resource_id: resource_id),
          DataONEManifestBuilder.new(uploads),
          MerrittDeleteBuilder.new(resource_id: resource_id),
          MerrittEmbargoBuilder.new(embargo_end_date: embargo_end_date)
        ]
      end
    end
  end
end
