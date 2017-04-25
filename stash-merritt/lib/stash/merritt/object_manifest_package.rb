require 'fileutils'
require 'ostruct'
require 'tmpdir'
require 'stash_engine'
require 'stash_datacite'
require 'datacite/mapping/datacite_xml_factory'
require 'stash/merritt/submission_package'

module Stash
  module Merritt
    class ObjectManifestPackage < SubmissionPackage

      attr_reader :root_url

      def initialize(resource:, root_url:)
        super(resource: resource, packaging: Stash::Sword::Packaging::BINARY)
        raise URI::InvalidURIError, "No root URL provided: #{root_url ? "'#{root_url}'" : 'nil'}" if root_url.blank?
        @resource = resource
        @root_url = to_uri(root_url)
        @manifest = create_manifest
      end

      def payload
        manifest
      end

      def create_manifest
        StashDatacite::PublicationYear.ensure_pub_year(resource)
        data_files = new_uploads.map { |upload| entry_for(upload) }
        system_files = builders.map { |builder| write_to_public(builder) }.compact
        manifest = ::Merritt::Manifest::Object.new(files: (system_files + data_files))
        manifest_path = workdir_path.join("#{resource_id}-manifest.checkm").to_s
        File.open(manifest_path, 'w') { |f| manifest.write_to(f) }
        manifest_path
      end

      def to_s
        "#{self.class}: object manifest submission package for resource #{resource_id} (#{resource_title}"
      end

      private

      def entry_for(upload)
        upload_file_name = upload.upload_file_name
        upload_url = upload.url
        throw ArgumentError, "No upload URL for upload #{upload.id} ('#{upload_file_name}')" unless upload_url

        upload_file_size = upload.upload_file_size
        OpenStruct.new(
          file_url: upload_url,
          file_size: (upload_file_size if upload_file_size > 0),
          file_name: upload_file_name
        )
      end

      def write_to_public(builder)
        return unless (path = builder.write_file(workdir))
        file_name = builder.file_name
        OpenStruct.new(
          file_url: public_url_for(file_name),
          hash_algorithm: 'md5',
          hash_value: Digest::MD5.file(path).to_s,
          file_size: File.size(path),
          file_name: file_name,
          mime_type: builder.mime_type
        )
      end

      def to_uri(uri_or_str)
        ::XML::MappingExtensions.to_uri(uri_or_str)
      end

      def public_url_for(pathname)
        URI.join(root_url.to_s, pathname)
      end

      def workdir_path
        @workdir_path ||= Rails.public_path.join("system/#{resource_id}")
      end

      def workdir
        @workdir ||= begin
          path = workdir_path.to_s
          FileUtils.mkdir_p(path)
          File.absolute_path(path)
        end
      end
    end
  end
end
