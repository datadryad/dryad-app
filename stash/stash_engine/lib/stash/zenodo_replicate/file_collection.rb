require 'stash/zenodo_replicate/zenodo_connection'

module Stash
  module ZenodoReplicate
    class FileCollection

      ZC = Stash::ZenodoReplicate::ZenodoConnection # keep code shorter with this

      def initialize(resource:, file_change_list_obj:)
        @resource = resource
        @file_change_list = file_change_list_obj

        @resp = ZC.standard_request(:get, "#{ZC.base_url}/api/deposit/depositions/#{@resource.zenodo_copies.data.first.deposition_id}")

        # existing_zenodo = @resp[:files].map { |f| f[:filename] }

        # @file_change_list = FileChangeList(resource: @resource, existing_zenodo_filenames: existing_zenodo)
      end

      # from the response o loaded dataset's json response[:links][:bucket]
      def synchronize_to_zenodo(bucket_url:)
        remove_files(zenodo_bucket_url: bucket_url)
        upload_files(zenodo_bucket_url: bucket_url)
      end

      def remove_files(zenodo_bucket_url:)
        @file_change_list.delete_list.each do |del_file|
          url = "#{zenodo_bucket_url}/#{ERB::Util.url_encode(del_file.upload_file_name)}"
          ZC.standard_request(:delete, url)
        end
      end

      def upload_files(zenodo_bucket_url:)
        @file_change_list.upload_list.each do |upload|
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


