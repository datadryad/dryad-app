require 'stash/merritt_download'
require 'http'
require 'stash/zenodo_replicate/copier_mixin'

# require 'stash/zenodo_replicate'
# resource = StashEngine::Resource.find(785)
# szc = Stash::ZenodoCopy.create(identifier_id: resource.identifier_id, resource_id: resource.id, copy_type: 'data', state: 'enqueued')
# szr = Stash::ZenodoReplicate::Copier.new(copy_id: @szc.id)
# szr.add_to_zenodo
#
# https://sandbox.zenodo.org/record/503933

module Stash
  module ZenodoReplicate
    class Copier

      # these are methods to help out for this class
      include Stash::ZenodoReplicate::CopierMixin

      def initialize(copy_id:)
        @assoc_method = :data
        @copy = StashEngine::ZenodoCopy.find(copy_id)
        @previous_copy = StashEngine::ZenodoCopy.where(identifier_id: @copy.identifier_id).where('id < ? ', @copy.id)
          .data.order(id: :desc).first
        @resource = StashEngine::Resource.find(@copy.resource_id)
        @file_collection = Stash::MerrittDownload::FileCollection.new(resource: @resource)
      end

      def add_to_zenodo
        # sanity checks
        error_if_not_enqueued
        error_if_replicating
        error_if_out_of_order

        @copy.update(state: 'replicating')
        @copy.increment!(:retries)

        # a zenodo deposit class
        @deposit = Deposit.new(resource: @resource)

        # download files from Merritt
        @file_collection.download_files

        # get/create the deposit(ion) from zenodo
        get_or_create_deposition
        @copy.update(deposition_id: @deposit.deposition_id)

        # update metadata
        @deposit.update_metadata

        # update files
        file_replicator = Files.new(resource: @resource, file_collection: @file_collection)
        file_replicator.replicate

        # submit it, publishing will fail if there isn't at least one file
        @deposit.publish
        @copy.update(state: 'finished')
      rescue Stash::MerrittDownload::DownloadError, Stash::ZenodoReplicate::ZenodoError, HTTP::Error => e
        # log this in the database so we can track it
        @copy.update(state: 'error', error_info: "#{e.class}\n#{e}")
        @copy.reload
        StashEngine::UserMailer.zenodo_error(@copy).deliver_now
      ensure
        @file_collection.cleanup_files
      end

      private

      # rubocop:disable Naming/AccessorMethodName
      def get_or_create_deposition
        @deposition_id = previous_deposition_id

        if @deposition_id.nil?
          # create a new deposit for this
          resp = @deposit.new_deposition
        else
          # retrieve and open for editing
          resp = @deposit.get_by_deposition(deposition_id: @deposition_id)
          @deposit.reopen_for_editing if resp[:state] == 'done'
        end
        resp
      end
      # rubocop:enable Naming/AccessorMethodName
    end
  end
end
