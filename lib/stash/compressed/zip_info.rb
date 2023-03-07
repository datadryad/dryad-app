require 'http'
require 'zip'
require 'stringio'
require 'byebug'

module Stash
  module Compressed
    class InvalidResponse < StandardError; end

    class ZipInfo
      attr_reader :presigned_url


      EOCD_RECORD_SIZE = 22
      ZIP64_EOCD_RECORD_SIZE = 56
      ZIP64_EOCD_LOCATOR_SIZE = 20

      MAX_STANDARD_ZIP_SIZE = 4_294_967_295

      def initialize(presigned_url:)
        @presigned_url = presigned_url
      end

      def size
        @size ||= get_size
      end

      def get_zip_file
        eocd_record = fetch(start: size - EOCD_RECORD_SIZE, length: EOCD_RECORD_SIZE)
        if size <= MAX_STANDARD_ZIP_SIZE
          cd_start, cd_size = get_central_directory_metadata_from_eocd(eocd_record)
          central_directory = fetch(start: cd_start, length: cd_size)
          sio = StringIO.new(central_directory)
          sio.binmode
          sio << eocd_record
          sio.rewind
          return sio
        else
          zip64_eocd_record = fetch(start: size - (EOCD_RECORD_SIZE + ZIP64_EOCD_LOCATOR_SIZE + ZIP64_EOCD_RECORD_SIZE),
                                    length: ZIP64_EOCD_RECORD_SIZE)
          zip64_eocd_locator = fetch(start: size - (EOCD_RECORD_SIZE + ZIP64_EOCD_LOCATOR_SIZE),
                                     length: ZIP64_EOCD_LOCATOR_SIZE)
          cd_start, cd_size = get_central_directory_metadata_from_eocd64(zip64_eocd_record)
          central_directory = fetch(start: cd_start, length: cd_size)
          sio = StringIO.new(central_directory, "wb+")
          sio << zip64_eocd_record
          sio << zip64_eocd_locator
          sio << eocd_record
          sio.rewind
          return sio
        end
      end

      private

      def get_size
        # the presigned URLs are only authorized as get requests, not head, so must do GET for size
        http = HTTP.headers('Range' => 'bytes=0-0').get(@presigned_url)
        raise Stash::Compressed::InvalidResponse if http.code > 399

        info = http.headers['Content-Range']
        m = info.match(%r{/(\d+)$})
        raise Stash::Compressed::InvalidResponse if m.nil?

        m[1].to_i
      end

      def get_eocd_record
        start_search = size - 2**16 # get last 64K of file, since comment may be up to 64K
        start_search = 0 if start_search < 0
        eocd_record = fetch(start: start_search, length: size - start_search)
        eocd_record.rindex("\x50\x4b\x05\x06") # find last EOCD record

      end

      def fetch(start:, length:)
        the_end = start + length - 1
        http = HTTP.headers('Range' => "bytes=#{start}-#{the_end}").get(@presigned_url)
        raise Stash::Compressed::InvalidResponse if http.code > 399

        http.body.to_s # now how to convert it to bytes or 4-byte integers?
      end

      def get_central_directory_metadata_from_eocd(eocd)
        cd_size = parse_little_endian_to_int(eocd[12..15])
        cd_start = parse_little_endian_to_int(eocd[16..19])
        [ cd_start, cd_size ]
      end

      def get_central_directory_metadata_from_eocd64(eocd64)
        cd_size = parse_little_endian_to_int(eocd64[40..47])
        cd_start = parse_little_endian_to_int(eocd64[48..55])
        [ cd_start, cd_size ]
      end

      def parse_little_endian_to_int(little_endian_bytes)
        # I want L<* for 4 bytes (32-bit) and Q<* for 8 bytes (64-bit)--unsigned, little endian
        format = ( little_endian_bytes.length == 4 ? 'L<*' : 'Q<*')
        little_endian_bytes.unpack(format).first
      end
    end
  end
end
