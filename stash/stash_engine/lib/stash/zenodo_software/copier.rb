require 'http'
require 'stash/zenodo_replicate/zenodo_connection'
require 'stash/zenodo_replicate/copier_mixin'
require 'stash/zenodo_replicate/deposit'
require 'stash/aws/s3'

# manual testing
# require 'stash/zenodo_software'
# Stash::ZenodoSoftware::Copier.test_submit(resource_id: xxxx, publication: false)
#
#
# The zenodo states are these (returned from their API for a dataset)
# unpublished submission -- state: unsubmitted,   submitted: false
# published              -- state: done,          submitted: true
# published-reopened     -- state: inprogress,    submitted: true
# published again        -- state: done,          submitted: true
# new_version            -- state: unsubmitted,   submitted: false
#
# Metadata-only changes are inconsistent, because they can be updated at time of change if the zenodo dataset is open, but
# if the dataset is closed then they can be deferred until publication when they might mean the dataset is re-opened and re-published.
#
# We may lose some history of metadata changes for zenodo software but we only care about published versions at Zenodo and
# at least the latest metadata changes on publication are present.  File changes get versioned internally at Zenodo.

# rubocop:disable Metrics/ClassLength
module Stash
  module ZenodoSoftware
    class Copier

      # This is just a convenience method for manually testing without going through delayed_job, but may be useful
      # as a utility manually submit sometime in the future.
      # It adds all entries for submitting in the zenodo_copies table as needed, and resets if needed to test again.
      def self.test_submit(resource_id:, publication: false)
        rep_type = (publication == true ? 'software_publish' : 'software')
        resource = StashEngine::Resource.find(resource_id)
        zc = StashEngine::ZenodoCopy.where(resource_id: resource.id).where(copy_type: rep_type).first
        if zc.nil?
          zc = StashEngine::ZenodoCopy.create(state: 'enqueued', identifier_id: resource.identifier_id,
                                              resource_id: resource.id, copy_type: rep_type)
        elsif zc.state != 'enqueued'
          zc.update(state: 'enqueued')
        end
        zen_soft_res = Stash::ZenodoSoftware::Copier.new(copy_id: zc.id)
        zen_soft_res.add_to_zenodo
      end

      ZE = Stash::ZenodoReplicate::ZenodoError

      # these are methods to help out for this class
      include Stash::ZenodoReplicate::CopierMixin

      def initialize(copy_id:)
        @assoc_method = :software
        @copy = StashEngine::ZenodoCopy.find(copy_id)
        @previous_copy = StashEngine::ZenodoCopy.where(identifier_id: @copy.identifier_id).where('id < ? ', @copy.id)
          .software.order(id: :desc).first
        @resp = {}
        @resource = StashEngine::Resource.find(@copy.resource_id)
        file_change_list = FileChangeList.new(resource: @resource)
        @file_collection = FileCollection.new(resource: @resource, file_change_list_obj: file_change_list)
        # I was creating this later, but it can be created earlier and eases testing to do it earlier
        @deposit = Stash::ZenodoReplicate::Deposit.new(resource: @resource)
      end

      # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
      def add_to_zenodo
        # sanity checks
        error_if_not_enqueued
        error_if_replicating
        error_if_bad_type
        error_if_out_of_order
        error_if_any_previous_unfinished
        error_if_more_than_one_replication_for_resource
        return if nothing_to_submit?

        @copy.update(state: 'replicating')
        @copy.increment!(:retries)

        @resp = if @previous_copy
                  @deposit.get_by_deposition(deposition_id: @previous_copy.deposition_id)
                else
                  @deposit.new_deposition
                end

        # update the database with current information on this dataset from Zenodo
        @copy.update(deposition_id: @resp[:id], software_doi: @resp[:metadata][:prereserve_doi][:doi],
                     conceptrecid: @resp[:conceptrecid])

        update_zenodo_relation

        return publish_dataset if @copy.copy_type == 'software_publish'

        return metadata_only_update unless files_changed?

        # if it's gotten here then we're making file changes, the main case

        if @resp[:state] == 'done' # then create new version
          @resp = @deposit.new_version(deposition_id: @previous_copy.deposition_id)
          # the doi and deposition id have changed, so update
          @copy.update(deposition_id: @resp[:id], software_doi: @resp[:metadata][:prereserve_doi][:doi],
                       conceptrecid: @resp[:conceptrecid])
        end

        # update metadata
        @deposit.update_metadata(software_upload: true, doi: @copy.software_doi)

        # update files
        @file_collection.synchronize_to_zenodo(bucket_url: @resp[:links][:bucket])

        @copy.update(state: 'finished', error_info: nil)

        # clean up the S3 storage of zenodo files that have been successfully replicated
        Stash::Aws::S3.delete_dir(s3_key: @resource.s3_dir_name(type: 'software'))
      rescue Stash::ZenodoReplicate::ZenodoError, HTTP::Error => e
        error_info = "#{Time.new} #{e.class}\n#{e}\n---\n#{@copy.error_info}" # append current error info first
        @copy.update(state: 'error', error_info: error_info)
        @copy.reload
        StashEngine::UserMailer.zenodo_error(@copy).deliver_now
      end
      # rubocop:enable Metrics/MethodLength, Metrics/AbcSize

      # Publishing should never come with file changes because it's a separate operation than updating files or metadata
      # However, metadata may not have been updated for locked datasets, so update it.
      def publish_dataset
        # Zenodo only allows publishing if there are file changes in this version, so it's different depending on status
        @deposit.reopen_for_editing if @resp[:state] == 'done'
        @deposit.update_metadata(software_upload: true, doi: @copy.software_doi)
        @deposit.publish if @resource.software_uploads.present_files.count > 0 # do not actually publish unless there are files
        @copy.update(state: 'finished', error_info: nil)
      end

      # no files are changing, but a previous version should always exist
      def metadata_only_update
        if @resp[:state] == 'done'
          # don't reopen for metadata changes and just update status
          # because metadata is only updated to public on publishing or if the version is unpublished and public won't see changes.
          @copy.update(state: 'finished',
                       error_info: "Warning: metadata wasn't updated because the last version was published, "\
                          "versioning of metadata-only changes isn't allowed in zenodo and the public should " \
                          'only see published metadata changes.')
          return
        end
        @deposit.update_metadata(software_upload: true, doi: @copy.software_doi)
        @copy.update(state: 'finished', error_info: nil)
      end

      private

      def error_if_any_previous_unfinished
        # items that don't have entries in the zenodo_copies table, need <= resource.id because otherwise it may pick up later
        # entries being edited that haven't been added yet.  TODO: Do I need to limit to only software-type uploads somehow?
        resources = @resource.identifier.resources
          .joins('LEFT JOIN stash_engine_zenodo_copies ON stash_engine_resources.id = stash_engine_zenodo_copies.resource_id')
          .where('stash_engine_zenodo_copies.resource_id IS NULL').where('stash_engine_resources.id <= ?', @resource)

        return if resources.count < 1

        unsubmitted_count = resources.map { |res| res.software_uploads.count }.reduce(0, :+)

        return unless unsubmitted_count.positive?

        raise ZE, "identifier_id #{@resource.identifier.id}: Cannot replicate a later version until earlier " \
              'versions with software have replicated. An earlier is missing from ZenodoCopies table.'
      end

      def error_if_more_than_one_replication_for_resource
        # this also catches an error if something is trying to publish that hasn't had a software-type submission yet for this resource
        return if @resource.zenodo_copies.where(copy_type: 'software').count == 1 # can have software and software_publish for same resource

        raise ZE, "resource_id #{@resource.id}: Exactly one replication of the same type (software or data) is allowed per resource."
      end

      def files_changed?
        change_count = @resource.software_uploads.deleted_from_version.count + @resource.software_uploads.newly_created.count
        change_count.positive?
      end

      def error_if_bad_type
        return if %w[software software_publish].include?(@copy.copy_type)

        raise ZE, "copy_id #{@copy.id}: Needs to be of the correct type (software not data)"
      end

      def nothing_to_submit?
        return false if submitted_before? || files_changed?

        @copy.update(state: 'finished', error_info: 'No software to submit to Zenodo for this resource id')
        true
      end

      def submitted_before?
        !@previous_copy.nil?
      end

      def update_zenodo_relation
        # only add link to zenodo software if they have any files left that they haven't deleted
        if @resource.software_uploads.where(file_state: %w[created copied]).count.positive?
          StashDatacite::RelatedIdentifier.add_zenodo_relation(resource_id: @resource.id, doi: @copy.software_doi)
        else
          StashDatacite::RelatedIdentifier.remove_zenodo_relation(resource_id: @resource.id, doi: @copy.software_doi)
        end
      end
    end
  end
end
# rubocop:enable Metrics/ClassLength
