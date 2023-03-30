module Stash
  module Compressed
    module S3Size
      BASE_HTTP = HTTP.use(normalize_uri: { normalizer: Stash::Download::NORMALIZER })
        .timeout(connect: 30, read: 180, write: 180).follow(max_hops: 10)

      # size and calc_size are the same as in ZipInfo maybe split into a base class or module
      def size
        @size ||= calc_size
      end

      def calc_size
        # the presigned URLs are only authorized as get requests, not head, so must do GET for size
        http = BASE_HTTP.headers('Range' => 'bytes=0-0').get(@presigned_url)
        raise Stash::Compressed::InvalidResponse, "Status code #{http.code} returned for GET range 0-0 for #{@presigned_url}" if http.code > 399

        info = http.headers['Content-Range']
        m = info&.match(%r{/(\d+)$})
        raise Stash::Compressed::InvalidResponse, "No valid size returned for #{@presigned_url}" if m.nil?

        m[1].to_i
      end
    end
  end
end
