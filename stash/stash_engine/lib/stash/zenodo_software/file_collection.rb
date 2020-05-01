module Stash
  module ZenodoSoftware
    # A class to ensure that the collection files represented in the database is available on the file system.
    class FileCollection

      # takes the resource for the files we want to manage
      def initialize(resource:)
        @resource = resource
      end

      def ensure_new_files_exist
        @resource.software_uploads.each do |upload|

        end
      end

    end
  end
end
