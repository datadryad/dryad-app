require 'http'
require 'stash/zenodo_software'
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
module Stash
  module ZenodoSoftware

    REPLI_ASSOC = {
      software: { s3: 'software', resource: :software_files },
      supp: { s3: 'supplemental', resource: :supp_files }
    }.with_indifferent_access.freeze

    class Copier
      ZC = Stash::ZenodoReplicate::ZenodoConnection

      # This is just a convenience method for manually testing without going through delayed_job, but may be useful
      # as a utility manually submit sometime in the future.
      # It adds all entries for submitting in the zenodo_copies table as needed, and resets if needed to test again.
      def self.test_submit(resource_id:, publication: false, type: 'software')
        rep_type = if type == 'software'
                     (publication == true ? 'software_publish' : 'software')
                   else
                     (publication == true ? 'supp_publish' : 'supp')
                   end
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

      def initialize(copy_id:, dataset_type: :software)
        raise 'dataset_type must be :software or :supp' unless Stash::ZenodoSoftware::REPLI_ASSOC.keys.map(&:intern).include?(dataset_type)

        # set up the associations that get used variably
        @dataset_type = dataset_type
        @resource_method = Stash::ZenodoSoftware::REPLI_ASSOC[@dataset_type][:resource]
        @s3_method = Stash::ZenodoSoftware::REPLI_ASSOC[@dataset_type][:s3]

        @copy = StashEngine::ZenodoCopy.find(copy_id)
        @previous_copy = StashEngine::ZenodoCopy.where(identifier_id: @copy.identifier_id).where('id < ? ', @copy.id)
          .send(@dataset_type).order(id: :desc).first
        @resp = {}
        @resource = StashEngine::Resource.find(@copy.resource_id)
        file_change_list = FileChangeList.new(resource: @resource, resource_method: @resource_method)
        @file_collection = FileCollection.new(file_change_list_obj: file_change_list, zc_id: @copy.id)
        # I was creating this later, but it can be created earlier and eases testing to do it earlier
        @deposit = Stash::ZenodoReplicate::Deposit.new(resource: @resource, zc_id: @copy.id)
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

        # make sure the dataset has the relationships for these things synchronized to zenodo
        StashDatacite::RelatedIdentifier.set_latest_zenodo_relations(resource: @resource)

        return if nothing_to_submit?

        @copy.reload
        @copy.update(state: 'replicating')
        @copy.increment!(:retries)

        # TODO: This should probably also consider a deposition_id in the current item in case it got one and failed
        @resp = if @previous_copy
                  @deposit.get_by_deposition(deposition_id: @previous_copy.deposition_id)
                else
                  @deposit.new_deposition
                end

        # update the database with current information on this dataset from Zenodo
        @copy.reload
        @copy.update(deposition_id: @resp[:id], software_doi: @resp[:metadata][:prereserve_doi][:doi],
                     conceptrecid: @resp[:conceptrecid])

        # make sure the dataset has the relationships for these things synchronized to zenodo
        StashDatacite::RelatedIdentifier.set_latest_zenodo_relations(resource: @resource)

        return publish_dataset if @copy.copy_type&.end_with?('_publish')

        return metadata_only_update unless files_changed?

        # if it's gotten here then we're making file changes, the main case

        if @resp[:state] == 'done' # then create new version
          @resp = @deposit.new_version(deposition_id: @previous_copy.deposition_id)
          # the doi and deposition id have changed, so update
          @copy.reload
          @copy.update(deposition_id: @resp[:id], software_doi: @resp[:metadata][:prereserve_doi][:doi],
                       conceptrecid: @resp[:conceptrecid])
        end

        # update metadata
        @deposit.update_metadata(dataset_type: @dataset_type, doi: @copy.software_doi)

        # update files
        @file_collection.synchronize_to_zenodo(bucket_url: @resp[:links][:bucket])

        # resources method is the method off resource to call to get file list for that type of file like software or supplemental
        # will raise exception if there are problems between file lists both places
        Stash::ZenodoSoftware::FileCollection.check_uploaded_list(resource: @resource, resource_method:
          @resource_method, deposition_id: @resp[:id], zc_id: @copy.id)

        # clean up the S3 storage of zenodo files that have been successfully replicated
        Stash::Aws::S3.new.delete_dir(s3_key: @resource.s3_dir_name(type: @s3_method))

        @copy.reload
        @copy.update(state: 'finished')

        # make sure the dataset has the relationships for these things sent to zenodo
        StashDatacite::RelatedIdentifier.set_latest_zenodo_relations(resource: @resource)
      rescue Stash::ZenodoReplicate::ZenodoError, HTTP::Error => e
        @copy.reload
        Stash::ZenodoReplicate::ZenodoConnection.log_to_database(item: "Zenodo final failure: #{e.class}\n#{e}", zen_copy: @copy)
        @copy.reload
        StashEngine::UserMailer.zenodo_error(@copy).deliver_now
      end
      # rubocop:enable Metrics/MethodLength, Metrics/AbcSize

      # Publishing should never come with file changes because it's a separate operation than updating files or metadata
      # However, metadata may not have been updated for locked datasets, so update it.
      def publish_dataset
        # Zenodo only allows publishing if there are file changes in this version, so it's different depending on status
        @deposit.reopen_for_editing if @resp[:state] == 'done'
        @deposit.update_metadata(dataset_type: @dataset_type, doi: @copy.software_doi)
        @deposit.publish if @resource.send(@resource_method).present_files.count > 0 # do not actually publish unless there are files
        @copy.update(state: 'finished')
      rescue Stash::ZenodoReplicate::ZenodoError => e
        revert_to_previous_version if e.message.include?('Validation error') && e.message.include?('files must differ from all previous versions')
      end

      # no files are changing, but a previous version should always exist
      def metadata_only_update
        if @resp[:state] == 'done'
          # don't reopen for metadata changes and just update status
          # because metadata is only updated to public on publishing or if the version is unpublished and public won't see changes.
          @copy.update(state: 'finished',
                       error_info: "Warning: metadata wasn't updated because the last version was published, " \
                                   "versioning of metadata-only changes isn't allowed in zenodo and the public should " \
                                   'only see published metadata changes.')
          return
        end
        @deposit.update_metadata(dataset_type: @dataset_type, doi: @copy.software_doi)
        @copy.update(state: 'finished')
      end

      private

      def error_if_any_previous_unfinished
        resources = @resource.identifier.resources.where('id < ?', @resource.id)

        resources.each do |res|
          next if res.send(@resource_method).present_files.count < 1 # none of these types of files

          copy_record = res.zenodo_copies.where('copy_type like ?', "#{@dataset_type}%").first
          if copy_record.nil? || copy_record.state != 'finished'
            raise ZE, "identifier_id #{@resource.identifier.id}: Cannot replicate a later version until earlier " \
                      "versions with files have replicated. Resource id #{res.id} is incomplete or not present in the ZenodoCopies table."
          end
        end
      end

      def error_if_more_than_one_replication_for_resource
        return if @resource.zenodo_copies.where(copy_type: @copy.copy_type).count == 1 # can have software and software_publish for same resource

        raise ZE, "resource_id #{@resource.id}: Exactly one replication of the same type (software or data) is allowed per resource."
      end

      def files_changed?
        change_count = @resource.send(@resource_method).deleted_from_version.count + @resource.send(@resource_method).newly_created.count
        change_count.positive?
      end

      def error_if_bad_type
        return unless @copy.copy_type.starts_with?('data')

        raise ZE, "copy_id #{@copy.id}: Needs to be of the correct type (not data)"
      end

      def nothing_to_submit?
        return false if submitted_before? || files_changed?

        @copy.update(state: 'finished', error_info: 'Nothing to submit to Zenodo for this resource id')
        true
      end

      def submitted_before?
        !@previous_copy.nil?
      end

      # this takes a deposit that hasn't changed and makes it the same deposition as the previous version to make Zenodo happy
      def revert_to_previous_version
        # get last that wasn't this deposition
        prev_copy = StashEngine::ZenodoCopy.send(@dataset_type.to_sym)
          .where(identifier_id: @resource.identifier_id)
          .where.not(deposition_id: @copy.deposition_id)
          .order(:resource_id).last
        curr_deposition_id = @copy.deposition_id

        # now set the information for these copy records to be the same deposition and software_doi as the previous version
        StashEngine::ZenodoCopy.where(deposition_id: curr_deposition_id).send(@dataset_type.to_sym).each do |copy|
          copy.update(deposition_id: prev_copy.deposition_id, software_doi: prev_copy.software_doi, note: 'no changes in this version')
        end

        # Delete an existing unpublished deposition resource. Note, only unpublished depositions may be deleted.
        # DELETE /api/deposit/depositions/:id
        # return code: 201 Created -- see https://developers.zenodo.org/#delete
        ZC.standard_request(:delete, "#{ZC.base_url}/api/deposit/depositions/#{curr_deposition_id}", zc_id: @zc_id)

        # also need to fix the related work since the deposition_id is changed
        StashDatacite::RelatedIdentifier.set_latest_zenodo_relations(resource: @resource)

        @copy.update(state: 'finished', error_info: 'Reverted to previous version because no files ultimately changed in this version.')
      end

    end
  end
end
