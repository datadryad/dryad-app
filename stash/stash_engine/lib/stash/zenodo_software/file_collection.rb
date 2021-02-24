require 'fileutils'
require 'stash/zenodo_replicate/zenodo_connection'

module Stash
  module ZenodoSoftware

    class FileError < Stash::ZenodoReplicate::ZenodoError; end

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
          digests = [ 'md5' ]
          digests.push(upload.digest_type) if upload.digest_type.present? && upload.digest.present?
          digests.uniq!
          
          out = streamer.stream(digest_types: digests)

          check_digests(streamer_response: out, file_model: upload)
        end
      end

      # contains response: and digest: keys
      def check_digests(streamer_response:, file_model:)
        out = streamer_response
        upload = file_model
        if out[:response].nil? || out[:response][:checksum].nil?
          raise FileError, "Error streaming file to Zenodo. No md5 digest returned:\n#{out[:response]}\nFile:#{upload.inspect}"
        end

        if out[:response][:checksum] != "md5:#{out[:digests]['md5']}"
          raise FileError, "Error MD5 digest doesn't match zenodo:\nResponse: #{out[:response][checksum]}\nCalculated: md5:#{out[:digests]['md5']}"
        end

        if upload.digest_type.present? && upload.digest.present? && out[:digests][upload.digest_type] != upload.digest
          raise FileError, "Error #{upload.digest_type} digest doesn't match database value:\nCalculated:#{out[:digests][upload.digest_type]}\n" \
              "Database: #{upload.digest}"
        end
      end
    end
  end
end
