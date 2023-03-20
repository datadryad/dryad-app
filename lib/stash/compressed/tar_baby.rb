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
      include Stash::Compressed::S3Size

      def initialize(presigned_url:)
        @presigned_url = presigned_url
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
