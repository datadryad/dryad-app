require 'fileutils'

module Stash
  module ZenodoSoftware

    class FileError < StandardError; end

    # A class to ensure that the collection files represented in the database is available on the file system.
    # Most major problems raise exceptions since if something goes wrong it should error and not proceed with bad data
    class FileCollection

      ZC = Stash::ZenodoReplicate::ZenodoConnection # keep code shorter with this

      # takes the resource for the files we want to manage
      def initialize(resource:)
        @resource = resource
      end

      # from the response o loaded dataset's json response[:links][:bucket]
      def synchronize_to_zenodo(bucket_url:)
        remove_files(zenodo_bucket_url: bucket_url)
        upload_files(zenodo_bucket_url: bucket_url)
      end

      def remove_files(zenodo_bucket_url:)
        @resource.software_uploads.deleted_from_version.each do |del_file|
          url = "#{zenodo_bucket_url}/#{ERB::Util.url_encode(del_file.upload_file_name)}"
          ZC.standard_request(:delete, url)
        end
      end

      def upload_files(zenodo_bucket_url:)
        @resource.software_uploads.newly_created.each do |upload|
          streamer = Streamer.new(file_model: upload, zenodo_bucket_url: zenodo_bucket_url)
          streamer.stream
        end
      end
    end
  end
end
