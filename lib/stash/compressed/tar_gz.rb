require 'http'
require 'rubygems/package'
require 'open3'

# test with files 14139 and 14140
# df = StashEngine::DataFile.find(14139)
# tgz = Stash::Compressed::TarGz.new(presigned_url: df.merritt_s3_presigned_url)
# tgz.file_entries

module Stash
  module Compressed
    class TarGz
      attr_reader :presigned_url
      include Stash::Compressed::S3Size

      def initialize(presigned_url:)
        @presigned_url = presigned_url
      end

      # tar reader entries appear to look like this:
      # <Gem::Package::TarReader::Entry:0x00007f7ab90359e0 @closed=false,
      #     @header=#<Gem::Package::TarHeader:0x00007f7ab9035f08 @checksum=8479, @devmajor=0, @devminor=0,
      #       @gid=1000, @gname="uym2", @linkname="", @magic="ustar", @mode=420, @mtime=1650476916,
      #       @name="EMDate_bimodals/D995_3_25/rep100/true_mus_clock3.txt", @prefix="", @size=4142,
      #       @typeflag="0", @uid=1000, @uname="uym2", @version=0, @empty=false>,
      #     @io=#<Zlib::GzipReader:0x00007f7ab8710928>, @orig_pos=166067200, @read=0>

      # I could create two classes and one block yield to the other, but this is short and simple enough I
      # think it's fine to have both decompression and untarring and create other classes if
      # needed for additional decompression/tar formats.  Maybe refactor it makes sense to reuse code later.
      def file_entries(sleep_time: 2, tries: 5)
        attempts ||= 0
        begin
          file_info = []
          # streams the response body in chunks
          response = BASE_HTTP.get(@presigned_url)

          raise HTTP::Error, "Bad status code #{response&.status&.code}" unless response.status.ok?

          Zlib::GzipReader.wrap(response.body) do |gz|
            Gem::Package::TarReader.new(gz) do |tar|
              tar.each do |entry|
                # puts entry.inspect
                file_info << { file_name: entry.full_name, uncompressed_size: entry.size }
              end
            end
          end
          file_info
        rescue HTTP::Error, ArgumentError => e # ArgumentError is from Ruby tar library
          Rails.logger.error("Error caught attempt #{attempts} -- #{e.message}")
          sleep sleep_time
          if (attempts += 1) < tries
            retry
          end
          raise(e)
        end
      end

      def fallback_file_entries
        file_info = []
        # Open3.capture3 info at https://www.honeybadger.io/blog/capturing-stdout-stderr-from-shell-commands-via-ruby/

        # example output from tar -ztv
        # -rwxr-xr-x  0 tracyh staff     422 Jun  1  2011 dppdiv_1.0b/bootstrap.sh
        stdout, stderr, _status = Open3.capture3("curl -s -L \"#{@presigned_url}\" | tar -ztv")

        stdout.each_line do |line|
          arr = line.strip.split(/\s+/, 9)
          my_fn = arr[-1]
          my_size = arr[4].to_i
          file_info << { file_name: my_fn, uncompressed_size: my_size }
        end
        raise Stash::Compressed::InvalidResponse, stderr if stdout.empty? && stderr.present?
        file_info
      end

      def entries_with_fallback
        entries = file_entries(sleep_time: 5, tries: 1)
        raise Stash::Compressed::InvalidResponse if entries.empty?

        entries
      rescue Stash::Compressed::InvalidResponse, ArgumentError
        fallback_file_entries
      end
    end
  end
end
