require 'stash/merritt_download'
require 'http'


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
        # @file_collection.path, @file_collection.info_hash
        zen = ZenodoConnection.new(resource: @resource, file_collection: @file_collection)
        zen.new_deposition

        # add files
        zen.send_files

        # finalize submission
        r = zen.publish
      rescue Stash::MerrittDownload::DownloadError, Stash::ZenodoReplicate::ZenodoError, HTTP::Error => ex
        puts "We would be logging an error here.\n#{ex.class}\n#{ex.to_s}"
        # log this somewhere in the database so we can track it
      ensure
        # ensure clean up or other actions every time
      end
    end
  end
end
