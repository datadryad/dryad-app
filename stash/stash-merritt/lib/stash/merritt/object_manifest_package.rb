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

      attr_reader :root_url, :manifest

      def initialize(resource:)
        super(resource: resource, packaging: Stash::Sword::Packaging::BINARY)
        @resource = resource
        @root_url = to_uri("https://#{Rails.application.default_url_options[:host]}/system/#{@resource.id}/")
        @manifest = create_manifest
      end

      def payload
        manifest
      end

      def create_manifest
        puts "XXXX create_manifest || S #{system_files} || D #{data_files}"
        StashDatacite::PublicationYear.ensure_pub_year(resource)
        manifest = ::Merritt::Manifest::Object.new(files: (system_files + data_files))
        # XXXX TODO write the manifest to S3 and return its presigned path
        #manifest_path = workdir_path.join("#{resource_id}-manifest.checkm").to_s
        #File.open(manifest_path, 'w') { |f| manifest.write_to(f) }
        "should be the manifest_path"
      end

      def to_s
        "#{self.class}: object manifest submission package for resource #{resource_id} (#{resource_title}"
      end

      private

      def data_files
        new_uploads.map { |upload| entry_for(upload) }
      end

      def system_files
        builders.map { |builder| write_to_public(builder) }.compact
      end

      def entry_for(upload)
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

      def write_to_public(builder)
        return unless (path = builder.write_s3_file("#{@resource.s3_dir_name}_man"))

        file_name = builder.file_name
        OpenStruct.new(
          file_url: public_url_for(path),
          # XXXXX TODO -- do we really need the MD5 and size here? can we get it from S3 instead of calculating?
#          hash_algorithm: 'md5',
#          hash_value: Digest::MD5.file(path).to_s,
#          file_size: File.size(path),
          file_name: file_name,
          mime_type: builder.mime_type
        )
      end

      def to_uri(uri_or_str)
        ::XML::MappingExtensions.to_uri(uri_or_str)
      end

      def public_url_for(pathname)
        # XXXXX TODO -- put a presigned generator here
        puts "XXXX getting presigned for #{pathname}"
        s3r = Aws::S3::Resource.new(region: APP_CONFIG[:s3][:region],
                                    access_key_id: APP_CONFIG[:s3][:key],
                                    secret_access_key: APP_CONFIG[:s3][:secret])        
        bucket = s3r.bucket(APP_CONFIG[:s3][:bucket])
        object = bucket.object(pathname)
        presigned = object.presigned_url(:get, expires_in: 1.day.to_i)
        puts "XXXX   - presigned is #{presigned}"
        presigned
      end

    end
  end
end
