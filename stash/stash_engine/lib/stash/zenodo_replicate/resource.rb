require 'stash/merritt_download'
require 'http'


# require 'stash/zenodo_replicate'
# resource = StashEngine::Resource.find(785)
# szr = Stash::ZenodoReplicate::Resource.new(resource: resource)
# szr.add_to_zenodo
#
# https://sandbox.zenodo.org/record/503933

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
        # @file_collection.path
        # @file_collection.info_hash

        # create new object for working with zenodo and start the deposit dataset with metadata
        # TODO: modify the zenodo stuff to take file collection( either in initialize or in send files) so it can validate digests
        # @file_collection.path, @file_collection.info_hash

        zen = ZenodoConnection.new(resource: @resource, file_collection: @file_collection)

        # either this
        resp = zen.new_deposition
        deposit_id = zen.deposit_id
        # or zen.update by deposition id

        # add files, this will mostly just raise an error if it can't upload something.
        zen.send_files

        # finalize submission
        resp = zen.publish

        # now see if I can create a new version by this way!
        resp = new_version_deposition(deposition_id: deposit_id)

        # it looks like resp[:latest_draft] is the URL we really want now.  The desposition in the end of the URL


      rescue Stash::MerrittDownload::DownloadError, Stash::ZenodoReplicate::ZenodoError, HTTP::Error => ex
        puts "We would be logging an error here.\n#{ex.class}\n#{ex.to_s}"
        # log this somewhere in the database so we can track it
      ensure
        # ensure clean up or other actions every time
      end
    end
  end
end
