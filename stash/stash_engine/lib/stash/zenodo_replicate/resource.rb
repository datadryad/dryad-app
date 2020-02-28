require 'stash/merritt_download'

# require 'stash/zenodo_replicate'
# resource = StashEngine::Resource.find(785)
# szr = Stash::ZenodoReplicate::Resource.new(resource: resource)
# szr.add_to_zenodo

module Stash
  module ZenodoReplicate

    class ReplicationError < StandardError; end

    class Resource

      def initialize(resource:)
        @resource = resource
      end

      def add_to_zenodo
        # download files from Merritt
        location = download_files

        # create new object for working with zenodo and start the deposit dataset with metadata
        zen = ZenodoConnection.new(resource: @resource, path: location)
        zen.new_deposition

        # add files
        zen.send_files

        # finalize submission
      rescue ReplicationError, Stash::ZenodoConnection::ZenodoError => ex
        # log this somewhere in the database so we can track it
      ensure
        # ensure clean up or other actions every time
      end

      # downloads files and returns directory location
      def download_files
        smdf = Stash::MerrittDownload::File.new(resource: @resource)

        copy_files = @resource.file_uploads.where(file_state: %w[created copied])
          .map(&:upload_file_name).append(%w[mrt-datacite.xml mrt-oaidc.xml stash-wrapper.xml]).flatten

        copy_files.each do |f|
          status = smdf.download_file(filename: f)
          raise ReplicationError, "Download: #{status[:error]}" unless status[:success]
        end

        smdf.path
      end
    end
  end
end
