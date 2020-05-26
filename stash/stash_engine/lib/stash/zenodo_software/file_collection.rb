require 'fileutils'

module Stash
  module ZenodoSoftware

    class FileError < StandardError; end

    # A class to ensure that the collection files represented in the database is available on the file system.
    # Most major problems raise exceptions since if something goes wrong it should error and not proceed with bad data
    class FileCollection
      attr_accessor :path

      # takes the resource for the files we want to manage
      def initialize(resource:)
        @resource = resource
        @path = resource.software_upload_dir
      end

      def ensure_local_files
        @resource.software_uploads.newly_created.each do |upload|
          zen_file = Stash::ZenodoSoftware::FileDownload.new(file_obj: upload)
          zen_file.download unless upload.url.blank?
          zen_file.check_file_exists
          zen_file.check_digest
        end
      end

      def cleanup_files
        FileUtils.rm_rf(@path)
      end
    end
  end
end
