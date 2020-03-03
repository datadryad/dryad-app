require 'fileutils'

module Stash
  module MerrittDownload

    class DownloadError < StandardError; end

    class FileCollection

      attr_reader :path, :info_hash

      def initialize(resource:)
        @resource = resource

        # the 'upload' path is a symlinked shared EFS mount on our servers
        @path = Rails.root.join('uploads', 'zenodo_replication', resource.id.to_s)
        FileUtils.mkdir_p(@path) # makes entire path to this file if is needed

        # sets up file download stuff for a resource, but different method for each file download
        @smdf = Stash::MerrittDownload::File.new(resource: @resource, path: @path)

        # Set info hash as files are downloaded.  key is filename, value is { success: <t/f>, sha256_digest:, md5_digest: }.
        # Unsuccessful files raise DownloadError.  We need status info for file saved in order to save and validate digests.
        @info_hash = {}
      end


      # downloads files and sets status in list, raises error if something fails
      def download_files
        copy_files = @resource.file_uploads.where(file_state: %w[created copied])

        copy_files.each do |f|
          status = @smdf.download_file(db_file: f )
          raise Stash::MerrittDownload::DownloadError, "Download: #{status[:error]}\nfile.id #{f.id}" unless status[:success]

          @info_hash[f.upload_file_name] = status
        end
      end
    end
  end
end