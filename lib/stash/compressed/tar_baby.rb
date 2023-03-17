require 'http'
require 'rubygems/package'

# test with files 14139 and 14140
# df = StashEngine::DataFile.find(14139)
# tar_baby = Stash::Compressed::TarBaby.new(presigned_url: df.merritt_s3_presigned_url)
# tar_baby.file_entries

module Stash
  module Compressed
    class TarBaby
      attr_reader :presigned_url

      def initialize(presigned_url:)
        @presigned_url = presigned_url
      end

      # size and calc_size are the same as in ZipInfo maybe split into a base class or module
      def size
        @size ||= calc_size
      end

      def calc_size
        # the presigned URLs are only authorized as get requests, not head, so must do GET for size
        http = HTTP.headers('Range' => 'bytes=0-0').get(@presigned_url)
        raise Stash::Compressed::InvalidResponse, "Status code #{http.code} returned for GET range 0-0 for #{@presigned_url}" if http.code > 399

        info = http.headers['Content-Range']
        m = info&.match(%r{/(\d+)$})
        raise Stash::Compressed::InvalidResponse, "No valid size returned for #{@presigned_url}" if m.nil?

        m[1].to_i
      end

      # tar reader entries appear to look like this
      # <Gem::Package::TarReader::Entry:0x00007f7ab90359e0 @closed=false,
      #     @header=#<Gem::Package::TarHeader:0x00007f7ab9035f08 @checksum=8479, @devmajor=0, @devminor=0,
      #       @gid=1000, @gname="uym2", @linkname="", @magic="ustar", @mode=420, @mtime=1650476916,
      #       @name="EMDate_bimodals/D995_3_25/rep100/true_mus_clock3.txt", @prefix="", @size=4142,
      #       @typeflag="0", @uid=1000, @uname="uym2", @version=0, @empty=false>,
      #     @io=#<Zlib::GzipReader:0x00007f7ab8710928>, @orig_pos=166067200, @read=0>

      # this also needs to be made much more robust.  Maybe also separate the compression from the tar reader
      def file_entries
        file_info = []
        # streams the response body in chunks
        response = HTTP.get(@presigned_url)
        Zlib::GzipReader.wrap(response.body) do |gz|
          Gem::Package::TarReader.new(gz) do |tar|
            tar.each do |entry|
              # puts entry.inspect
              file_info << { file_name: entry.full_name, uncompressed_size: entry.size }
            end
          end
        end
        file_info
      end
    end
  end
end
