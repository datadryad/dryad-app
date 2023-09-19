require 'fileutils'

module Stash
  module S3Download

    class DownloadError < StandardError; end

    class FileCollection

      attr_reader :path, :info_hash
      # path is just the path where files are stored
      # info_hash is key=filename and value={success: t/f, md5_hex, sha256_hex}

      def initialize(resource:)
        @resource = resource

        # the 'upload' path is a symlinked shared EFS mount on our servers
        @path = Rails.root.join('uploads', 'zenodo_replication', resource.id.to_s)
        FileUtils.mkdir_p(@path) # makes entire path to this file if is needed

        # sets up file download stuff for a resource, but different method for each file download
        @smdf = Stash::S3Download::File.new(resource: @resource, path: @path)

        # Set info hash as files are downloaded.  key=filename, value = { success: <t/f>, sha256_digest:, md5_digest: }.
        # Unsuccessful files raise DownloadError.
        @info_hash = {}
      end

      # downloads files and sets status in list, raises error if something fails
      def download_files
        copy_files = @resource.data_files.where(file_state: %w[created copied])

        copy_files.each do |f|
          status = @smdf.download_file(db_file: f)
          raise Stash::S3Download::DownloadError, "Download: #{status[:error]}\nfile.id #{f.id}" unless status[:success]

          @info_hash[f.upload_file_name] = status
        end
      end

      def cleanup_files
        FileUtils.rm_rf(@path)
      end
    end
  end
end
