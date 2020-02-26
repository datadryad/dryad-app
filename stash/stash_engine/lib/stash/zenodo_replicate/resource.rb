require 'stash/merritt_download'

module Stash
  module ZenodoReplicate

    class ReplicationError < StandardError; end

    class Resource

      def initialize(resource:)
        @resource = resource
      end

      def add_to_zenodo

        # download files from Merritt to local for re-uploading
        status = download_files
        return

        # create new zenodo object

        # add files

        # finalize actions

      rescue ReplicationError => ex

      end

      def download_files
        smdf = Stash::MerrittDownload::File.new(resource: resource)

        copy_files = @resource.file_uploads.where(file_state: %w[created copied])
                         .map(&:upload_file_name).append(%w[mrt-datacite.xml mrt-oaidc.xml stash-wrapper.xml]).flatten

        copy_files.each do |f|
          status = smdf.download_file(filename: f)
          return status unless status[:success]
        end

        { success: true }
      end
    end
  end
end