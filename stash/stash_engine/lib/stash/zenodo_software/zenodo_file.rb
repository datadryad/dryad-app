require 'stash/zenodo_replicate/zenodo_connection'
require 'digest'

module Stash
  module ZenodoSoftware
    class ZenodoFile

      ZC = Stash::ZenodoReplicate::ZenodoConnection # keep code shorter with this

      # from the previous dataset load json response[:links][:bucket]
      def initialize(bucket_url:)
        @bucket_url = bucket_url
      end

      def upload(file_model:)
        upload_file = file_model.calc_file_path
        upload_url = "#{@bucket_url}/#{ERB::Util.url_encode(file_model.upload_file_name)}"
        md5 = Digest::MD5.file(upload_file).hexdigest

        # remove the json content content type
        # PUT /api/files/<bucket-id>/<filename>
        resp = ZC.standard_request(:put, upload_url, body: File.open(upload_file, 'rb'), headers: { 'Content-Type': nil })

        unless resp[:checksum] == "md5:#{md5}"
          raise Stash::ZenodoReplicate::ZenodoError, "Mismatched digests for #{upload_url}\n#{resp[:checksum]} vs #{md5}"
        end

        resp
      end

      def remove(file_model:)
        # DELETE /api/files/<bucket-id>/<filename>
        url = "#{@bucket_url}/#{ERB::Util.url_encode(file_model.upload_file_name)}"
        ZC.standard_request(:delete, url)
      end
    end
  end
end
