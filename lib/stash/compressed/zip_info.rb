require 'http'
require 'stringio'
require 'charlock_holmes/string'
require 'zip'
require 'down/http'
require 'open3'

module Stash
  module Compressed
    class InvalidResponse < StandardError; end
    class ZipError < StandardError; end

    class ZipInfo
      attr_reader :presigned_url

      include Stash::Compressed::S3Size

      def initialize(presigned_url:)
        @presigned_url = presigned_url
      end

      # this gets out the file entries in the central directory
      # See https://blog.yaakov.online/zip64-go-big-or-go-home/ for a good diagram and a simple case

      # See https://rhardih.io/2021/04/listing-the-contents-of-a-remote-zip-archive-without-downloading-the-entire-file/
      # but it doesn't handle zip64 files

      # Other resources:
      # https://en.wikipedia.org/wiki/ZIP_(file_format)

      # https://betterprogramming.pub/how-to-know-zip-content-without-downloading-it-87a5b30be20a (makes some bad assumptions
      # about the end of central directory record and is missing the zip64 case)

      # I tried both RubyZip and ZipTricks to see if I could get them to parse out files only from the central directory
      # but they didn't work correctly.  ZipTricks is supposed to be able to handle it, but I could never get it to work.

      # I finally had to use the spec and examples and roll my own.
      def file_entries
        file_info = []

        ss = StringScanner.new(central_directory)

        until ss.scan_until(/\x50\x4b\x01\x02/).nil? # central directory signature

          # compressed size
          ss.pos += 16
          compressed_size = ss.peek(4).unpack1('L<')

          # uncompressed size
          ss.pos += 4
          uncompressed_size = ss.peek(4).unpack1('L<')

          # file name length
          ss.pos += 4
          file_name_length = ss.peek(2).unpack1('S<')

          # filename
          ss.pos += 18
          file_name = ss.peek(file_name_length)
          enc = file_name.detect_encoding[:ruby_encoding] || 'UTF-8'
          file_name.force_encoding(enc)

          # try to make UTF-8 and in the rare case it fails then make bad characters into question marks
          file_name = file_name.encode('UTF-8', invalid: :replace, undef: :replace, replace: '?')

          # forward past the file name
          ss.pos += file_name_length

          # if compressed or uncompressed equal 4294967295 then it's a zip64 file and they need recalculation
          if compressed_size == 4_294_967_295 || uncompressed_size == 4_294_967_295

            unless ss.peek(2) == "\x01\x00"
              raise Stash::Compressed::ZipError, "Something is wrong with the zip64 file signature for #{file_name} for #{@presigned_url}"
            end

            # uncompressed size
            ss.pos += 4
            uncompressed_size = ss.peek(8).unpack1('Q<')

            # compressed size
            ss.pos += 8
            compressed_size = ss.peek(8).unpack1('Q<')

            ss.pos += 8
          end

          file_info << { file_name: file_name, compressed_size: compressed_size, uncompressed_size: uncompressed_size }
        end

        file_info
      end

      # for the standard 32-bit zip file
      def eocd_record32
        return @eocd_record32 if @eocd_record32

        start_search = size - (2**16) # get last 64K of file, since comment may be up to 64K
        start_search = 0 if start_search < 0
        eocd_record = fetch(start: start_search, length: size - start_search)
        eocd_start = eocd_record.rindex("\x50\x4b\x05\x06") # find last EOCD record

        if eocd_start.nil?
          raise Stash::Compressed::ZipError, "No end of central directory record found for #{@presigned_url}, likely " \
                                             'not a zip file, a multivolume zip or corrupted (such as transferred in ASCII mode)'
        end

        @eocd_record32 = eocd_record[eocd_start..]
      end

      # for the zip64 file
      # https://blog.yaakov.online/zip64-go-big-or-go-home/ gives a good diagram of how both end of central directory records are laid out
      def eocd_record64
        return @eocd_record64 if @eocd_record64

        end_search = size - eocd_record32.length
        start_search = end_search - (2**16) # get last 64K of file before 32-bit EOCD record
        start_search = 0 if start_search < 0

        eocd_record = fetch(start: start_search, length: end_search - start_search)
        eocd_start = eocd_record.rindex("\x50\x4b\x06\x06") # find other EOCD record (x0606 instead of x0506 for zip64)
        raise Stash::Compressed::ZipError, "No zip64 end of central directory found for #{@presigned_url}" if eocd_start.nil?

        @eocd_record64 = eocd_record[eocd_start..]
      end

      # zip64s have a certain signature in the 32-bit EOCD record
      def zip64?
        eocd_record32[16..19].unpack1('L<') == 4_294_967_295 # 0xFFFFFFFF
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
        http = BASE_HTTP.headers('Range' => "bytes=#{start}-#{the_end}").get(@presigned_url)
        raise Stash::Compressed::InvalidResponse if http.code > 399

        http.body.to_s
      end

      def central_directory_metadata_from_eocd(eocd)
        cd_size = parse_little_endian_to_int(eocd[12..15])
        cd_start = parse_little_endian_to_int(eocd[16..19])
        raise Stash::Compressed::ZipError, "Central directory is out of bounds for #{@presigned_url}" if cd_start + cd_size > size

        [cd_start, cd_size]
      end

      def central_directory_metadata_from_eocd64(eocd64)
        cd_size = parse_little_endian_to_int(eocd64[40..47])
        cd_start = parse_little_endian_to_int(eocd64[48..55])
        raise Stash::Compressed::ZipError, "Central directory is out of bounds for #{@presigned_url}" if cd_start + cd_size > size

        [cd_start, cd_size]
      end

      def parse_little_endian_to_int(little_endian_bytes)
        # I want L< for 4 bytes (32-bit) and Q< for 8 bytes (64-bit)--unsigned, little endian
        format = (little_endian_bytes.length == 4 ? 'L<' : 'Q<')
        little_endian_bytes.unpack1(format)
      end

      # this reads the whole file using rubyzip input stream
      # but it doesn't return size of zip64s always
      def fallback_file_entries1
        file_info = []
        # response = BASE_HTTP.get(@presigned_url)
        # response.body.each do |chunk|
        remote_file = Down::Http.open(@presigned_url)
        Zip::InputStream.open(remote_file) do |io|
          while (entry = io.get_next_entry)
            file_info << { file_name: entry.name, uncompressed_size: entry.size }
            # puts "Name: #{entry.name}, Size: #{entry.size}, Compressed Size: #{entry.compressed_size}"
          end
        end
        file_info
      end

      # this maybe seems to do better with zip64 if java jar is installed.  I would use zipinfo but it
      # doesn't work with piping input and only displays help output rather than parsing the zip file.
      # I believe the only way to use zipinfo is to write the file to disk and then run zipinfo on it
      # which would take up lots of disk space for items that are large zip files.
      def fallback_file_entries2
        file_info = []
        stdout, stderr, _status = Open3.capture3("curl -s -L \"#{@presigned_url}\" | jar -tv")
        stdout.each_line do |line|
          arr = line.strip.split(/\s+/, 8)
          my_fn = arr[-1]
          my_size = arr[0].to_i
          file_info << { file_name: my_fn, uncompressed_size: my_size }
        end
        # I don't know if the following does much since jar doesn't seem to always give good error messages like zipinfo
        # and instead just gives blank output for many items it can't really parse.
        raise Stash::Compressed::ZipError, stderr if stdout.empty? && stderr.present?

        file_info
      end

      def entries_with_fallback
        entries = file_entries
        raise Stash::Compressed::InvalidResponse if entries.empty?

        entries
      rescue Stash::Compressed::ZipError, Stash::Compressed::InvalidResponse
        begin
          if size < 8e+9.to_i # 8GB and the dumb zip library writes something to disk when it streams so it fills up disk
            entries = fallback_file_entries1
            return entries unless entries.empty?
          end
        rescue Zip::GPFBit3Error
          # ignore
          # this is a known issue with rubyzip
        end

        fallback_file_entries2
      end

    end
  end
end
