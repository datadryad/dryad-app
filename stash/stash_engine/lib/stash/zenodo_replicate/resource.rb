require 'stash/merritt_download'

# require 'stash/zenodo_replicate'
# resource = StashEngine::Resource.find(785)
# szr = Stash::ZenodoReplicate::Resource.new(resource: resource)
# szr.add_to_zenodo

module Stash
  module ZenodoReplicate
    class Resource

      attr_reader :file_collection

      def initialize(resource:)
        @resource = resource
        @file_collection = Stash::MerrittDownload::FileCollection.new(resource: @resource)
      end

      def add_to_zenodo
        # download files from Merritt
        @file_collection.download_files

        # create new object for working with zenodo and start the deposit dataset with metadata
        # TODO: modify the zenodo stuff to take file collection( either in initialize or in send files) so it can validate digests
        zen = ZenodoConnection.new(resource: @resource, path: @file_collection.path)
        zen.new_deposition

        # add files
        zen.send_files

        # finalize submission
        zen.publish
      rescue Stash::MerrittDownload::DownloadError, Stash::ZenodoConnection::ZenodoError => ex
        # log this somewhere in the database so we can track it
      ensure
        # ensure clean up or other actions every time
      end
    end
  end
end
