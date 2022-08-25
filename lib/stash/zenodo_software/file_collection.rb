require 'stash/zenodo_replicate/zenodo_connection'
require 'stash/zenodo_software/streamer' # may be needed if loaded from zenodo_replicate

module Stash
  module ZenodoSoftware
    class FileError < Stash::ZenodoReplicate::ZenodoError; end

    # update collection of files to zenodo
    class FileCollection

      FILE_RETRY_WAIT = 5

      ZC = Stash::ZenodoReplicate::ZenodoConnection # keep code shorter with this

      def initialize(file_change_list_obj:, zc_id:)
        @zc_id = zc_id
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
          ZC.standard_request(:delete, url, zc_id: @zc_id)
        end
      end

      def upload_files(zenodo_bucket_url:)
        @file_change_list.upload_list.each do |upload|
          next if upload.upload_file_size.nil? || upload.upload_file_size == 0

          streamer = Streamer.new(file_model: upload, zenodo_bucket_url: zenodo_bucket_url, zc_id: @zc_id)
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

      # resource method is :software_files or :supp_files, the method from resource to get the right type of files
      def self.check_uploaded_list(resource:, resource_method:, deposition_id:, zc_id:)
        response = Stash::ZenodoReplicate::Deposit.get_by_deposition(deposition_id: deposition_id, zc_id: zc_id)
        resource.reload # just in case it's out of date
        dry_files = resource.public_send(resource_method).present_files
        zen_files = response[:files]

        # below creates hash with key as filename and the original hash as value, nice function in the 2.6+ ruby versions
        zen_hsh = zen_files.to_h { |item| [item[:filename], item] }

        file_errors = []
        dry_files.each do |dry_file|
          zen_file = zen_hsh[dry_file.upload_file_name]

          if zen_file.blank?
            file_errors << "#{dry_file.upload_file_name} (id: #{dry_file.id}) exists in the Dryad database but not in Zenodo " \
                'after Zenodo indicated a successful upload'
            next
          end

          if zen_file[:filesize] != dry_file.upload_file_size
            file_errors << "Dryad and Zenodo file sizes do not match for #{dry_file.upload_file_name} (id: #{dry_file.id}): " \
              "Dryad size is #{dry_file.upload_file_size} and Zenodo size is #{zen_file[:filesize]}"
          end
        end

        if zen_files&.count != dry_files&.count
          file_errors << "The number of Dryad files (#{dry_files&.count}) does not match the number of Zenodo files (#{zen_files&.count})"
        end

        raise FileError, file_errors.join("\n") unless file_errors.empty?
      end

    end
  end
end
