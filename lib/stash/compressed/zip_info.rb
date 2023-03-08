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

      def zip_directory
        sio = StringIO.new('', 'rb+')
        # sio.write('\x50\x4b\x03\x04\x2d\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00')
        # sio.write('\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00')
        sio.write(central_directory)
        # set offset to 0
        sio.write("#{eocd_record32[0..15]}#{"\x20\x00\x00\x00"}#{eocd_record32[20..-1]}")
        sio.rewind

        File.open('testfile.zip', 'wb') do |f|
          f.write(sio.read)
        end

        sio.rewind

        # rz_central = Zip::CentralDirectory.new

        # blah = Zip::CentralDirectory.send(:read_central_directory_entries, sio)

        byebug

        Zip::InputStream.open(sio) do |io|
          while (entry = io.get_next_entry)
            puts "#{entry.name}: '#{io.read}'"
          end
        end
      end

      def file_entries
        file_info = []

        ss = StringScanner.new(central_directory)

        until ss.scan_until(/\x50\x4b\x01\x02/).nil? # central directory signature

          # compressed size
          ss.pos += 16
          compressed_size = ss.peek(4).unpack('L<*').first

          # uncompressed size
          ss.pos += 4
          uncompressed_size = ss.peek(4).unpack('L<*').first

          # file name length
          ss.pos += 4
          file_name_length =  ss.peek(2).unpack("S<*").first

          # filename
          ss.pos += 18
          file_name = ss.peek(file_name_length).force_encoding('utf-8')

          # forward past the file name
          ss.pos += file_name_length

          # if compressed and uncompressed equal 4294967295 then it's a zip64 file and they need recalculation
          if compressed_size == 4294967295 && uncompressed_size == 4294967295

            assert(peek(2) == "\x01\x00") # zip64 extra field signature

            # uncompressed size
            ss.pos += 4
            uncompressed_size = ss.peek(8).unpack('Q<*').first

            # compressed size
            ss.pos += 8
            compressed_size = ss.peek(8).unpack('Q<*').first

            ss.pos += 8
          end

          file_info << { file_name: file_name, compressed_size: compressed_size, uncompressed_size: uncompressed_size }
        end

        file_info
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

      def get_size
        # the presigned URLs are only authorized as get requests, not head, so must do GET for size
        http = HTTP.headers('Range' => 'bytes=0-0').get(@presigned_url)
        raise Stash::Compressed::InvalidResponse if http.code > 399

        info = http.headers['Content-Range']
        m = info.match(%r{/(\d+)$})
        raise Stash::Compressed::InvalidResponse if m.nil?

        m[1].to_i
      end

      # for the standard 32-bit zip file
      def eocd_record32
        return @eocd_record32 if @eocd_record32

        start_search = size - 2**16 # get last 64K of file, since comment may be up to 64K
        start_search = 0 if start_search < 0
        eocd_record = fetch(start: start_search, length: size - start_search)
        eocd_start = eocd_record.rindex("\x50\x4b\x05\x06") # find last EOCD record
        @eocd_record32 = fetch(start: eocd_start, length: size - eocd_start)
      end

      # for the zip64 file
      # https://blog.yaakov.online/zip64-go-big-or-go-home/ gives a good diagram of how both end of central directory records are laid out
      def eocd_record64
        return @eocd_record64 if @eocd_record64

        end_search = size - eocd_record32.length
        start_search = end_search - 2**16 # get last 64K of file before 32-bit EOCD record
        start_search = 0 if start_search < 0

        eocd_record = fetch(start: start_search, length: end_search - start_search)

        eocd_start = eocd_record.rindex("\x50\x4b\x06\x06") # find other EOCD record
        @eocd_record64 = fetch(start: eocd_start, length: end_search - eocd_start)
      end

      # zip64s have a certain signature in the 32-bit EOCD record
      def zip64?
        eocd_record32[8..19] == "\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff"
      end

      def central_directory
        return @central_directory if @central_directory
        if zip64?
          cd_start, cd_size = central_directory_metadata_from_eocd64(eocd_record64)
        else
          cd_start, cd_size = central_directory_metadata_from_eocd(eocd_record32)
        end
        @central_directory = fetch(start: cd_start, length: cd_size)
      end

      def fetch(start:, length:)
        the_end = start + length - 1
        http = HTTP.headers('Range' => "bytes=#{start}-#{the_end}").get(@presigned_url)
        raise Stash::Compressed::InvalidResponse if http.code > 399

        http.body.to_s # now how to convert it to bytes or 4-byte integers?
      end

      def central_directory_metadata_from_eocd(eocd)
        cd_size = parse_little_endian_to_int(eocd[12..15])
        cd_start = parse_little_endian_to_int(eocd[16..19])
        [ cd_start, cd_size ]
      end

      def central_directory_metadata_from_eocd64(eocd64)
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
