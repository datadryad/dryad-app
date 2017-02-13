require 'fileutils'
require 'tmpdir'
require 'stash_engine'
require 'stash_datacite'
require 'zip'
require 'datacite/mapping/datacite_xml_factory'
require 'stash/merritt/submission_package/data_one_manifest_builder'
require 'stash/merritt/submission_package/merritt_datacite_builder'
require 'stash/merritt/submission_package/merritt_delete_builder'
require 'stash/merritt/submission_package/merritt_oaidc_builder'
require 'stash/merritt/submission_package/stash_wrapper_builder'

module Stash
  module Merritt
    class SubmissionPackage
      attr_reader :resource
      attr_reader :zipfile

      def initialize(resource:)
        raise ArgumentError, "Resource (#{resource.id}) must have an identifier before submission" unless resource.identifier_str
        @resource = resource
        @zipfile = create_zipfile
      end

      def resource_id
        resource.id
      end

      def dc3_xml
        @dc3_xml ||= datacite_xml_factory.build_datacite_xml(datacite_3: true)
      end

      def resource_title
        primary_title = resource.titles.where(title_type: nil).first
        primary_title.title.to_s if primary_title
      end

      def create_zipfile
        StashDatacite::PublicationYear.ensure_pub_year(resource)
        zipfile_path = File.join(workdir, "#{resource_id}_archive.zip")
        Zip::File.open(zipfile_path, Zip::File::CREATE) do |zipfile|
          builders.each { |builder| write_to_zipfile(zipfile, builder) }
          new_uploads.each { |upload| add_to_zipfile(zipfile, upload) }
        end
        zipfile_path
      end

      def cleanup!
        FileUtils.remove_dir(workdir)
        @zipfile = nil
      end

      def to_s
        "#{self.class}: submission package for resource #{resource_id} (#{resource_title}"
      end

      private

      def write_to_zipfile(zipfile, builder)
        return unless (file = builder.write_file(workdir))
        zipfile.add(builder.file_name, file)
      end

      def add_to_zipfile(zipfile, upload)
        path = File.join(resource.upload_dir, upload.upload_file_name)
        raise ArgumentError, "Upload file '#{upload.upload_file_name}' not found in directory #{resource.upload_dir}" unless File.exist?(path)
        zipfile.add(upload.upload_file_name, path)
      end

      def builders
        @builders ||= [
          StashWrapperBuilder.new(dcs_resource: dc4_resource, version_number: version_number, uploads: uploads),
          MerrittDataciteBuilder.new(datacite_xml_factory),
          MerrittOAIDCBuilder.new(resource_id: resource_id),
          DataONEManifestBuilder.new(uploads),
          MerrittDeleteBuilder.new(resource_id: resource_id)
        ]
      end

      def total_size_bytes
        @total_size_bytes ||= uploads.inject(0) { |sum, u| sum + u.upload_file_size }
      end

      def version_number
        @version_number ||= resource.version_number
      end

      def uploads
        resource.current_file_uploads
      end

      def new_uploads
        resource.new_file_uploads
      end

      def datacite_xml_factory
        @datacite_xml_factory ||= Datacite::Mapping::DataciteXMLFactory.new(doi_value: resource.identifier_value, se_resource_id: resource_id, total_size_bytes: total_size_bytes, version: version_number)
      end

      def dc4_resource
        @dc4_resource ||= datacite_xml_factory.build_resource
      end

      def workdir
        @workdir ||= begin
          path = resource.upload_dir
          FileUtils.mkdir_p(path)
          tmpdir = Dir.mktmpdir('uploads', path)
          File.absolute_path(tmpdir)
        end
      end

    end
  end
end
