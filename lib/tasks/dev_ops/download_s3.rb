# :nocov:
require 'http'

module Tasks
  module DevOps
    class DownloadS3

      def initialize(path:)
        @path = path
        @http = HTTP.follow(max_hops: 2)
      end

      def download(file_obj:)
        dl_url = file_obj.s3_staged_presigned_url
        resp = @http.get(dl_url)

        File.binwrite(File.join(@path, file_obj.upload_file_name), resp.body)
      end
    end
  end
end
# :nocov:
