require 'http'
require 'stash/zenodo_replicate/zenodo_connection'
require 'stash/zenodo_replicate/resource_mixin'
require 'byebug'

module Stash
  module ZenodoSoftware
    class Resource

      # these are methods to help out for this class
      include Stash::ZenodoReplicate::ResourceMixin

      def initialize(resource:)
        @assoc_method = :software
        @resource = resource
        @file_collection = FileCollection.new(resource: @resource)
      end

      def add_to_zenodo
        # sanity checks
        error_if_not_enqueued
        error_if_replicating
        error_if_out_of_order
        # error_if_previous_unfinished

        r = HTTP.get('http://example.org/')
        byebug

        # database status for this copy
        # third_copy_record = @resource.zenodo_copies.data.first
        # third_copy_record.update(state: 'replicating')
        # third_copy_record.increment!(:retries)

        # a zenodo deposit class
        # @deposit = Deposit.new(resource: @resource)

        # download files from Merritt
        # @file_collection.download_files

        # get/create the deposit(ion) from zenodo
        # get_or_create_deposition
        # third_copy_record.update(deposition_id: @deposit.deposition_id)

        # update metadata
        # @deposit.update_metadata

        # update files
        # file_replicator = Files.new(resource: @resource, file_collection: @file_collection)
        # file_replicator.replicate

        # submit it, publishing will fail if there isn't at least one file
        # @deposit.publish
        # third_copy_record.update(state: 'finished')
        'pusdog'
      rescue Stash::MerrittDownload::DownloadError, Stash::ZenodoReplicate::ZenodoError, HTTP::Error => ex
        record = @resource.zenodo_copies.software.first
        if record.nil?
          record = StashEngine::ZenodoCopy.create(resource_id: @resource.id, identifier_id: @resource.identifier.id, copy_type: 'software')
        end
        record.update(state: 'error', error_info: "#{ex.class}\n#{ex}")
      ensure
        # @file_collection.cleanup_files
      end

      private

      def error_if_any_previous_unfinished
        # all the previous resources must've replicated to zenodo to make the current file changes

        # items that don't have entries in the zenodo_copies table
        zenodo_copies = @resource.identifier.resources.
          joins("LEFT JOIN stash_engine_zenodo_copies ON stash_engine_resources.id = stash_engine_zenodo_copies.resource_id").
          where(stash_engine_zenodo_copies.resource_id.nil)

        # items that aren't successfully finished
        zenodo_copies = @resource.indentifier.zenodo_copies.where('resource_id < ?', @resource.id).where("state <> 'finished'")
      end

    end
  end
end
