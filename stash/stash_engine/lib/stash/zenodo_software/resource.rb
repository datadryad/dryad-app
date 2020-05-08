require 'http'
require 'stash/zenodo_replicate/zenodo_connection'
require 'stash/zenodo_replicate/resource_mixin'
require 'byebug'

module Stash
  module ZenodoSoftware
    class Resource

      ZE = Stash::ZenodoReplicate::ZenodoError

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
        error_if_any_previous_unfinished
        error_if_more_than_one_replication_for_resource

        # database status for this copy
        copy_record = @resource.zenodo_copies.software.first
        copy_record.update(state: 'replicating')
        copy_record.increment!(:retries)

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
        r = HTTP.get('http://example.org/')
      rescue Stash::MerrittDownload::DownloadError, Stash::ZenodoReplicate::ZenodoError, HTTP::Error => ex
        record = @resource.zenodo_copies.software.last
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
          where('stash_engine_zenodo_copies.resource_id IS NULL').count

        raise ZE, "identifier_id #{@resource.identifier.id}: Cannot replicate a later version until earlier " \
              'have replicated. Earlier is missing from ZenodoCopies table.' if zenodo_copies > 0
      end

      def error_if_more_than_one_replication_for_resource
        raise ZE, "resource_id #{@resource.id}: Only one replication of the same type (software or data) " \
              'is allowed per resource.' if @resource.zenodo_copies.software.count > 1
      end
    end
  end
end
