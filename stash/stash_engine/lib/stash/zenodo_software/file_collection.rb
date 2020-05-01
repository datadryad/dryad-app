module Stash
  module ZenodoSoftware

    class FileError < StandardError; end

    # A class to ensure that the collection files represented in the database is available on the file system.
    class FileCollection

      attr_accessor :path

      # takes the resource for the files we want to manage
      def initialize(resource:)
        @resource = resource
        @path = resource.software_upload_path
      end

      def ensure_files
        @resource.software_uploads.newly_created.each do |upload|
          if upload.url.blank?
            check_file_exists?(upload)
            check_digest(upload)
          else
            puts 'this is a file download from the internets'
            # URL upload
          end

        end
      end

      private

      def check_file_exists?(file_obj)
        return if File.exist?(File.join(@path, file_obj.upload_file_name))
        raise FileError, "Uploaded file doesn't exist: resource_id: #{file_obj.resource_id}, file_id: #{file_obj.id}, " \
          "name: #{file_obj.upload_file_name}"
      end

      def check_digest; end

    end
  end
end
