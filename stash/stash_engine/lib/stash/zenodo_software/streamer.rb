require 'stash/aws/s3'
require 'http'
require 'digest'

module Stash
  module ZenodoSoftware
    class Streamer

      ZC = Stash::ZenodoReplicate::ZenodoConnection # keep code shorter with this

      DIGEST_INITIALIZERS = {
        'md5' => -> { Digest::MD5.new },
        'sha-1' => -> { Digest::SHA1.new },
        'sha-256' => -> { Digest::SHA256.new },
        'sha-384' => -> { Digest::SHA384.new },
        'sha-512' => -> { Digest::SHA512.new }
      }.with_indifferent_access.freeze

      def initialize(file_model:, zenodo_bucket_url:)
        # on one end we'll have S3 or an HTTP URL and on the other end of the pipe the zenodo put request that looks like
        # PUT "#{@bucket_url}/#{ERB::Util.url_encode(file_model.upload_file_name)}"
        # ZC.standard_request(:put, upload_url, body: File.open(upload_file, 'rb'), headers: { 'Content-Type': nil })

        @file_model = file_model
        @upload_url = "#{zenodo_bucket_url}/#{ERB::Util.url_encode(file_model.upload_file_name)}"
      end

      # some useful information that may be helpful if we need ot modify this later
      # https://aws.amazon.com/blogs/developer/downloading-objects-from-amazon-s3-using-the-aws-sdk-for-ruby/
      # https://janko.io/httprb-is-great/
      # https://github.com/httprb/http/pull/560
      # https://www.elastic.co/blog/streaming-post-requests-to-elastic-apm-in-ruby-with-http-rb-and-io-pipe
      #
      # Based on the last example (www.elastic.co).  However, they suggest using transfer-encoding 'chunked' which is
      # a model that Zenodo doesn't accept. If using chunked with zenodo it returns "file is smaller than expected" error.
      #
      # The only way to really stream this correctly is to set the expected size from the Content-Length header which always
      # seems to be set by S3 and is usually set for most web servers and static files.  However dynamic content from outside
      # web servers may use chunked and not supply a size (0) which means those streaming uploads will fail when going to Zenodo.
      #
      # This takes an argument of the digests types you want returned as an array, see DIGEST_INITIALIZERS for types.  It returns
      # the zenodo response and the hexdigests for the types you specify
      def stream(digest_types: [])
        set_up_empty_digests(digest_types: digest_types)

        read_pipe, write_pipe = IO.pipe
        read_pipe.define_singleton_method(:rewind) { nil }
        write_pipe.binmode

        response = HTTP.timeout(connect: 30, read: 60).timeout(6.hours.to_i).follow(max_hops: 10).get(@file_model.zenodo_replication_url)

        put_response = nil
        request_thread = Thread.new do
          put_response = ZC.standard_request(:put, @upload_url,
                              body: read_pipe,
                              headers: { 'Content-Type': nil, 'Content-Length': response.headers['Content-Length'] })
        end

        size = 0
        response.body.each do |chunk|
          size += chunk.length
          accumulate_digests(chunk: chunk)
          write_pipe.write(chunk)
        end

        write_pipe.close
        request_thread.join

        raise "Size is wrong" if size != response.headers['Content-Length'].to_i

        { response: put_response, digests: hex_digests }
      rescue HTTP::Error => e
        raise ZenodoError, "Error retrieving HTTP URL for duplication #{@file_model.zenodo_replication_url}\n" \
            "Original error: #{e}\n#{e.backtrace.join("\n")}"
      end

      private

      def set_up_empty_digests(digest_types:)
        @digest_accumulator = {}
        digest_types.each do |a_type|
          raise "Digest Type #{a_type} is unknown" unless DIGEST_INITIALIZERS.keys.include?(a_type)
          @digest_accumulator[a_type] = DIGEST_INITIALIZERS[a_type].call
        end
      end

      def accumulate_digests(chunk:)
        @digest_accumulator.each_pair do |_k, v|
          v.update(chunk)
        end
      end

      def hex_digests
        # output hexdigests
        digests = {}
        @digest_accumulator.each_pair do |k, v|
          digests[k] = v.hexdigest
        end
        digests
      end
    end
  end
end
