require 'stash/zenodo_replicate/zenodo_connection'
require 'stash/zenodo_software/streamer' # may be needed if loaded from zenodo_replicate

module Stash
  module ZenodoSoftware
    class FileError < Stash::ZenodoReplicate::ZenodoError; end

    # update collection of files to zenodo
    class FileCollection

      FILE_RETRY_WAIT = 5

      ZC = Stash::ZenodoReplicate::ZenodoConnection # keep code shorter with this

      def initialize(resource:, file_change_list_obj:)
        @resource = resource
        @file_change_list = file_change_list_obj
      end

      # from the response o loaded dataset's json response[:links][:bucket]
      def synchronize_to_zenodo(bucket_url:)
        remove_files(zenodo_bucket_url: bucket_url)
        upload_files(zenodo_bucket_url: bucket_url)
      end

      def remove_files(zenodo_bucket_url:)
        @file_change_list.delete_list.each do |del_file|
          url = "#{zenodo_bucket_url}/#{ERB::Util.url_encode(del_file)}"
          ZC.standard_request(:delete, url)
        end
      end

      def upload_files(zenodo_bucket_url:)
        @file_change_list.upload_list.each do |upload|
          streamer = Streamer.new(file_model: upload, zenodo_bucket_url: zenodo_bucket_url)
          digests = ['md5']
          digests.push(upload.digest_type) if upload.digest_type.present? && upload.digest.present?
          digests.uniq!

          retries = 0
          begin
            out = streamer.stream(digest_types: digests)
          rescue Stash::ZenodoReplicate::ZenodoError, HTTP::Error
            # rubocop:disable Style/GuardClause
            if (retries += 1) <= 3
              sleep FILE_RETRY_WAIT
              retry
            else
              raise
            end
            # rubocop:enable Style/GuardClause
          end

          check_digests(streamer_response: out, file_model: upload)
        end
      end

      # contains response: and digest: keys
      # rubocop:disable Metrics/AbcSize
      def check_digests(streamer_response:, file_model:)
        out = streamer_response
        upload = file_model
        if out[:response].nil? || out[:response][:checksum].nil?
          raise FileError, "Error streaming file to Zenodo. No md5 digest returned:\n#{out[:response]}\nFile:#{upload.inspect}"
        end

        if out[:response][:checksum] != "md5:#{out[:digests]['md5']}"
          raise FileError, "Error MD5 digest doesn't match zenodo:\nResponse: #{out[:response][:checksum]}\nCalculated: md5:#{out[:digests]['md5']}"
        end

        return unless upload.digest_type.present? && upload.digest.present? && out[:digests][upload.digest_type] != upload.digest

        raise FileError, "Error #{upload.digest_type} digest doesn't match database value:\nCalculated:#{out[:digests][upload.digest_type]}\n" \
              "Database: #{upload.digest}"
      end
      # rubocop:enable Metrics/AbcSize
    end
  end
end
