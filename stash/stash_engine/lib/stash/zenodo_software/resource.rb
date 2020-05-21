require 'http'
require 'stash/zenodo_replicate/zenodo_connection'
require 'stash/zenodo_replicate/resource_mixin'
require 'stash/zenodo_replicate/deposit'
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

      # TODO: refactor to make smaller/simpler later if I can
      # rubocop:disable Metrics/MethodLength, Metrics/AbcSize, Metrics/CyclomaticComplexity
      def add_to_zenodo
        # sanity checks
        error_if_not_enqueued
        error_if_replicating
        error_if_out_of_order
        error_if_any_previous_unfinished
        error_if_more_than_one_replication_for_resource
        return if nothing_to_submit?

        # database status for this copy
        zenodo_sfw = @resource.zenodo_copies.software.last
        zenodo_sfw.update(state: 'replicating')
        zenodo_sfw.increment!(:retries)

        @deposit = Stash::ZenodoReplicate::Deposit.new(resource: @resource)

        if zenodo_sfw.copy_type == 'software_publish'
          # hit publish if that is the action.
          # TODO: will publishing fail if no file changes but just metadata changes from an old version? This gets more complicated if so.
          @deposit.publish
          zenodo_sfw.update(state: 'finished', deposition_id: previous_submission.deposition_id, software_doi: previous_submission.software_doi)
          return
        end

        # download and prepare any files that are software to be uploaded again to Zenodo
        @file_collection.ensure_local_files

        if submitted_before?
          if previous_submission_published?
            # generate new version based on the old version
            resp = @deposit.new_version(deposition_id: previous_submission.deposition_id)
            # save the new DOI and deposition_id
            zenodo_sfw.update(deposition_id: resp[:id], software_doi: resp[:doi_url])
          else
            # this version should be open already, so just retrieve it and update database
            resp = @deposit.get_by_deposition(deposition_id: previous_submission.deposition_id)
            zenodo_sfw.update(deposition_id: previous_submission.deposition_id, software_doi: previous_submission.software_doi)
          end
        else
          # create entirely new dataset
          resp = @deposit.new_deposition
          zenodo_sfw.update(deposition_id: resp[:id], software_doi: resp[:doi_url])
        end

        # update metadata
        @deposit.update_metadata(doi: zenodo_sfw.software_doi)

        # synchronize files
        @file_collection.synchronize_to_zenodo(bucket_url: resp[:links][:bucket])

        zenodo_sfw.update(state: 'finished')
        @file_collection.cleanup_files # only cleanup files after success and finished, keep on fs so we have them otherwise
      rescue Stash::ZenodoReplicate::ZenodoError, HTTP::Error => ex
        record = @resource.zenodo_copies.software.last
        if record.nil?
          record = StashEngine::ZenodoCopy.create(resource_id: @resource.id, identifier_id: @resource.identifier.id, copy_type: 'software')
        end
        record.update(state: 'error', error_info: "#{ex.class}\n#{ex}")
      end
      # rubocop:enable Metrics/MethodLength, Metrics/AbcSize, Metrics/CyclomaticComplexity

      private

      def error_if_any_previous_unfinished
        # all the previous resources must've replicated to zenodo to make the current file changes

        # items that don't have entries in the zenodo_copies table
        zenodo_copies = @resource.identifier.resources
          .joins('LEFT JOIN stash_engine_zenodo_copies ON stash_engine_resources.id = stash_engine_zenodo_copies.resource_id')
          .where('stash_engine_zenodo_copies.resource_id IS NULL').count

        return if zenodo_copies < 1

        raise ZE, "identifier_id #{@resource.identifier.id}: Cannot replicate a later version until earlier " \
              'have replicated. Earlier is missing from ZenodoCopies table.'
      end

      def error_if_more_than_one_replication_for_resource
        return if @resource.zenodo_copies.where(copy_type: 'software').count == 1
        raise ZE, "resource_id #{@resource.id}: Only one replication of the same type (software or data) is allowed per resource."
      end

      def files_changed?
        change_count = @resource.software_uploads.deleted_from_version.count + @resource.software_uploads.newly_created.count
        change_count.positive?
      end

      def nothing_to_submit?
        return false if submitted_before? || files_changed?

        my_copy = @resource.zenodo_copies.software.last
        my_copy.update(state: 'finished', error_info: 'No software to submit to Zenodo for this resource id')
        true
      end

      def submitted_before?
        !previous_submission.nil?
      end

      def previous_submission
        @prev_submission ||= StashEngine::ZenodoCopy.where(identifier_id: @resource.identifier_id)
          .where('resource_id <> ? ', @resource.id).software.order(resource_id: :desc).last
      end

      def previous_submission_published?
        return true if submitted_before? && previous_submission.copy_type == 'software_publish'
        false
      end
    end
  end
end
