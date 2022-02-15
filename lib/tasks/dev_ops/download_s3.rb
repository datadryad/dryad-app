require 'http'

module DevOps
  class DownloadS3

    def initialize(path:)
      @path = path
      @http = HTTP.follow(max_hops: 2)
    end

    def download(file_obj:)
      dl_url = file_obj.direct_s3_presigned_url
      resp = @http.get(dl_url)

      File.open(File.join(@path, file_obj.upload_file_name), 'wb') do |dest|
        dest.write(resp.body) # slurp it all at once

        # below writes streaming chunk by chunk which may be better and reduce resource usage for large files
        # stream it a chunk at a time
        # resp.body.each do |chunk|
        #   dest.write(chunk)
        # end
      end
    end
  end
end
