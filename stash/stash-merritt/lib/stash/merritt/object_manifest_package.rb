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

      def initialize(resource:)
        super(resource: resource, packaging: Stash::Sword::Packaging::BINARY)
        puts 'XXXX omp i a'
        @resource = resource
        puts 'XXXX omp i b'
        @root_url = to_uri("https://#{Rails.application.default_url_options[:host]}/system/#{@resource.id}/")
        puts 'XXXX omp i c'
        @manifest = create_manifest
        puts 'XXXX omp i d'
      end

      def payload
        @manifest
      end

      def create_manifest
        puts 'XXXX omp cm a'
        puts "XXXX create_manifest || S #{system_files} || D #{data_files}"
        puts 'XXXX omp cm b'
        StashDatacite::PublicationYear.ensure_pub_year(resource)
        # generate the manifest via the merritt-manifest gem
        manifest = ::Merritt::Manifest::Object.new(files: (system_files + data_files))

        # Save a copy of the manifest in S3 for debugging if needed, but the actual
        # merritt submission will use the local file
        Stash::Aws::S3.put(file_path: "#{resource.s3_dir_name}/manifest/manifest.checkm",
                           contents: manifest.write_to_string)
        puts "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX YYYYYYY #{manifest.write_to_string} XXXXXXXXXXXXXXXXXXXXXXXXX"
        puts 'XXXX cm after a'
        manifest_path = workdir_path.join("#{resource_id}-manifest.checkm").to_s
        puts "XXXX cm after b2 #{manifest_path}"
        File.open(manifest_path, 'w') { |f| manifest.write_to(f) }
        puts "XXXX cm after c #{manifest_path}"
        manifest_path
      end

      def to_s
        "#{self.class}: object manifest submission package for resource #{resource_id} (#{resource_title}"
      end

      private

      def data_files
        new_uploads.map { |upload| data_file_entry(upload) }
      end

      def system_files
        builders.map { |builder| system_file_entry(builder) }.compact
      end

      def data_file_entry(upload)
        upload_file_name = upload.upload_file_name
        upload_url = upload.url || upload.direct_s3_presigned_url
        throw ArgumentError, "No upload URL for upload #{upload.id} ('#{upload_file_name}')" unless upload_url

        upload_file_size = upload.upload_file_size
        OpenStruct.new(
          file_url: upload_url,
          file_size: (upload_file_size if upload_file_size > 0),
          file_name: upload_file_name,
          hash_algorithm: (upload.digest_type if upload.digest?),
          hash_value: (upload.digest if upload.digest?)
        )
      end

      def system_file_entry(builder)
        puts 'XXXX omp sfe a'
        return unless (path = builder.write_s3_file("#{@resource.s3_dir_name}/manifest"))

        puts "XXXX omp sfe b XXXXXXXXXXXXXXXXXXXXXXXXXX #{path}"
        file_name = builder.file_name
        OpenStruct.new(
          file_url: Stash::Aws::S3.presigned_download_url(path),
          file_name: file_name,
          mime_type: builder.mime_type
        )
      end

      def to_uri(uri_or_str)
        ::XML::MappingExtensions.to_uri(uri_or_str)
      end

      def workdir_path
        @workdir_path ||= Rails.public_path.join("system/#{resource_id}")
        FileUtils.mkdir_p(@workdir_path)
        @workdir_path
      end

    end
  end
end
