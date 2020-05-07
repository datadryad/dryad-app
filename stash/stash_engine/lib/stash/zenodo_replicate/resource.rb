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

      def initialize(resource:)
        @resource = resource
        @file_collection = Stash::MerrittDownload::FileCollection.new(resource: @resource)
      end

      def add_to_zenodo
        # sanity checks
        error_if_not_enqueued
        error_if_replicating
        error_if_out_of_order

        # database status for this copy
        third_copy_record = @resource.zenodo_copies.data.first
        third_copy_record.update(state: 'replicating')
        third_copy_record.increment!(:retries)

        # a zenodo deposit class
        @deposit = Deposit.new(resource: @resource)

        # download files from Merritt
        @file_collection.download_files

        # get/create the deposit(ion) from zenodo
        get_or_create_deposition
        third_copy_record.update(deposition_id: @deposit.deposition_id)

        # update metadata
        @deposit.update_metadata

        # update files
        file_replicator = Files.new(resource: @resource, file_collection: @file_collection)
        file_replicator.replicate

        # submit it, publishing will fail if there isn't at least one file
        @deposit.publish
        third_copy_record.update(state: 'finished')
      rescue Stash::MerrittDownload::DownloadError, Stash::ZenodoReplicate::ZenodoError, HTTP::Error => ex
        # log this in the database so we can track it
        record = StashEngine::ZenodoCopy.where(resource_id: @resource.id).first_or_create
        record.update(state: 'error', error_info: "#{ex.class}\n#{ex}", identifier_id: @resource.identifier.id)
      ensure
        @file_collection.cleanup_files
      end

      private

      # error if not starting as enqueued
      def error_if_not_enqueued
        return if @resource.zenodo_copies.data.first&.state == 'enqueued'

        raise ZenodoError, "resource_id #{@resource.id}: You should never start replicating unless starting from an enqueued state"
      end

      # return an error if replicating already, shouldn't start another replication
      def error_if_replicating
        repli_count = @resource.identifier.zenodo_copies.where(state: %w[replicating error]).count
        # rubocop goes bonkers on this and suggests guardclause but when you do it suggests an if statement
        # rubocop:disable Style/GuardClause
        if repli_count.positive?
          raise ZenodoError, "identifier_id #{@resource.identifier.id}: Cannot replicate a version while a previous version " \
              'is replicating or has an error'
        end
        # rubocop:enable Style/GuardClause
      end

      def error_if_out_of_order
        # this is a little similar to error_if_replicating, but catches defered or other odd states
        prev_unfinished_count = StashEngine::ZenodoCopy.where(identifier_id: @resource.identifier_id)
          .where('id < ?', @resource.zenodo_copies.data.first.id).where.not(state: 'finished').count
        return if prev_unfinished_count == 0

        raise ZenodoError, "identifier_id #{@resource.identifier.id}: Cannot replicate a version when a previous version " \
              'has not replicated yet. Items must replicate in order.'
      end

      def previous_deposition_id
        last = @resource.identifier.zenodo_copies.where.not(deposition_id: nil).last
        return nil if last.nil?

        last.deposition_id
      end

      # rubocop:disable Naming/AccessorMethodName
      def get_or_create_deposition
        @deposition_id = previous_deposition_id

        if @deposition_id.nil?
          # create a new deposit for this
          resp = @deposit.new_deposition
        else
          # retrieve and open for editing
          resp = @deposit.get_by_deposition(deposition_id: @deposition_id)
          @deposit.reopen_for_editing unless resp[:state] == 'inprogress'
        end
        resp
      end
      # rubocop:enable Naming/AccessorMethodName
    end
  end
end
