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

      def stream
        # Stash::Aws::S3
        # example Stash::Aws::S3.delete_file(s3_key: s3_key)
        #
        # I think this example exposes a block (lots of bad answers, too) but for uplaod to S3
        # https://stackoverflow.com/questions/35349485/upload-csv-stream-from-ruby-to-s3/57624557
        #
        # This may be what I want using the block https://aws.amazon.com/blogs/developer/downloading-objects-from-amazon-s3-using-the-aws-sdk-for-ruby/
        # The stream will not retry failed requests so :hmm
        #
        # It also allows downloading in parts which could avoid overwhelming the memory
        #
        # Or just create a presigned URL and stream it all with http.rb.  I think this is easier.

        # for streaming, the http.rb object should take an enumerable with each or an io object with read, so
        # Using the AWS object as the request returns cannot determine size of body: #<struct Aws::S3::Types::GetObjectOutput
        # It may be that https://github.com/httprb/http/pull/560 fixes this
        # resp = ZC.standard_request(:put, @upload_url,
        #                            body: Stash::Aws::S3.get_block(s3_key: @file_model.calc_s3_path),
        #                            headers: { 'Content-Type': nil })


        # This fails with message "file is smaller than expected"
        # signed_url = Stash::Aws::S3.presigned_download_url(s3_key: @file_model.calc_s3_path)
        #
        # resp = ZC.standard_request(:put, @upload_url,
        #                            body: HTTP.get(signed_url).body,
        #                            headers: { 'Content-Type': nil, 'Transfer-Encoding': 'chunked' }).flush

        # if I need to calculate digests in the each, then perhaps I need to wrap it further with my own "each" and have it
        # do the extra file calculations inside.
        #
        # Maybe this is closer to what I want
        # https://www.elastic.co/blog/streaming-post-requests-to-elastic-apm-in-ruby-with-http-rb-and-io-pipe

        signed_url = Stash::Aws::S3.presigned_download_url(s3_key: @file_model.calc_s3_path)

        read_pipe, write_pipe = IO.pipe
        read_pipe.define_singleton_method(:rewind) { nil }
        write_pipe.binmode

        response = HTTP.get(signed_url)

        request_thread = Thread.new do
          # 'Transfer-Encoding': 'chunked' allows it to do it without a size set.
          ZC.standard_request(:put, @upload_url,
                              body: read_pipe,
                              headers: { 'Content-Type': nil, 'Content-Length': response.headers['Content-Length'] })
        end

        response.body.each do |chunk|
          write_pipe.write(chunk)
        end

        write_pipe.close
        request_thread.join
      end
    end
  end
end
