require 'stash/aws/s3'
require 'http'

module Stash
  module ZenodoSoftware
    class Streamer

      ZC = Stash::ZenodoReplicate::ZenodoConnection # keep code shorter with this

      def initialize(file_model:, zenodo_bucket_url:)
        # on one end we'll have S3 or an HTTP URL and on the other end of the pipe the zenodo put request that looks like
        # PUT "#{@bucket_url}/#{ERB::Util.url_encode(file_model.upload_file_name)}"
        # ZC.standard_request(:put, upload_url, body: File.open(upload_file, 'rb'), headers: { 'Content-Type': nil })

        @file_model = file_model
        @upload_url = "#{zenodo_bucket_url}/#{ERB::Util.url_encode(file_model.upload_file_name)}"
      end

      # some useful information that may be helpful if we need ot modify this later
      # https://aws.amazon.com/blogs/developer/downloading-objects-from-amazon-s3-using-the-aws-sdk-for-ruby/
      # https://github.com/httprb/http/pull/560
      # https://www.elastic.co/blog/streaming-post-requests-to-elastic-apm-in-ruby-with-http-rb-and-io-pipe
      #
      # Based on the last example (www.elastic.co).  However, they suggest using transfer-encoding 'chunked' which is
      # a model that Zenodo doesn't accept. If using chunked with zenodo it returns "file is smaller than expected" error.
      #
      # The only way to really stream this correctly is to set the expected size from the Content-Length header which always
      # seems to be set by S3 and is usually set for most web servers and static files.  However dynamic content from outside
      # web servers may use chunked and not supply a size (0) which means those streaming uploads will fail when going to Zenodo.
      def stream

        signed_url = Stash::Aws::S3.presigned_download_url(s3_key: @file_model.calc_s3_path)

        read_pipe, write_pipe = IO.pipe
        read_pipe.define_singleton_method(:rewind) { nil }
        write_pipe.binmode

        # TODO: we may need some more parameters for this to be optimal
        response = HTTP.get(signed_url)

        request_thread = Thread.new do
          ZC.standard_request(:put, @upload_url,
                              body: read_pipe,
                              headers: { 'Content-Type': nil, 'Content-Length': response.headers['Content-Length'] })
        end

        response.body.each do |chunk|
          # TODO: other stuff with the chunks to add size and to calculate the digest(s)
          write_pipe.write(chunk)
        end

        write_pipe.close
        request_thread.join
      end
    end
  end
end
