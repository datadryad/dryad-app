require 'http'
require 'stash/zenodo_replicate/zenodo_connection'
require 'stash/zenodo_replicate/resource_mixin'
require 'stash/zenodo_replicate/deposit'
require 'byebug'

# manual testing
# require 'stash/zenodo_software'
# resource = StashEngine::Resource.find(2926)
# zc = StashEngine::ZenodoCopy.create(state: 'enqueued', identifier_id: resource.identifier_id, resource_id: resource.id, copy_type: 'software')
# zen_soft_res = Stash::ZenodoSoftware::Resource.new(copy_id: zc.id)
# zen_soft_res.add_to_zenodo
#
# Why does this have a different recid ?
# (byebug) resp[:metadata]
# {"prereserve_doi"=>{"doi"=>"10.5072/zenodo.623097", "recid"=>623097}}
module Stash
  module ZenodoSoftware
    class Resource

      def self.test_submit(resource_id:, publication: false)
        rep_type = (publication == true ? 'software_publish': 'software')
        resource = StashEngine::Resource.find(resource_id)
        zc = StashEngine::ZenodoCopy.where(resource_id: resource.id).where(copy_type: rep_type).first
        if zc.nil?
          zc = StashEngine::ZenodoCopy.create(state: 'enqueued', identifier_id: resource.identifier_id,
            resource_id: resource.id, copy_type: rep_type)
        elsif zc.state != 'enqueued'
          zc.update(state: 'enqueued')
        end
        zen_soft_res = Stash::ZenodoSoftware::Resource.new(copy_id: zc.id)
        zen_soft_res.add_to_zenodo
      end

      ZE = Stash::ZenodoReplicate::ZenodoError

      # these are methods to help out for this class
      include Stash::ZenodoReplicate::ResourceMixin

      def initialize(copy_id:)
        @assoc_method = :software
        @copy = StashEngine::ZenodoCopy.find(copy_id)
        @previous_copy = StashEngine::ZenodoCopy.where(identifier_id: @copy.identifier_id).where('id < ? ', @copy.id)
          .software.order(id: :desc).first
        @resource = StashEngine::Resource.find(@copy.resource_id)
        @file_collection = FileCollection.new(resource: @resource)
      end

      # rubocop:disable Metrics/MethodLength, Metrics/AbcSize, Metrics/CyclomaticComplexity
      def add_to_zenodo
        # sanity checks
        error_if_not_enqueued
        error_if_replicating
        error_if_out_of_order
        error_if_any_previous_unfinished
        error_if_more_than_one_replication_for_resource
        return if nothing_to_submit?

        @copy.update(state: 'replicating')
        @copy.increment!(:retries)

        @deposit = Stash::ZenodoReplicate::Deposit.new(resource: @resource)

        if @copy.copy_type == 'software_publish'
          # hit publish if that is the action.
          # TODO: will publishing fail if no file changes but just metadata changes from an old version? This gets more complicated if so.
          resp = @deposit.get_by_deposition(deposition_id: @previous_copy.deposition_id)
          @deposit.publish
          @copy.update(state: 'finished', deposition_id: resp[:id], software_doi: resp[:metadata][:prereserve_doi][:doi],
                       conceptrecid: resp[:conceptrecid] )
          return
        end

        # download and prepare any files that are software to be uploaded again to Zenodo
        @file_collection.ensure_local_files

        resp = nil
        if submitted_before?
          if previous_submission_published?
            byebug
            resp = @deposit.new_version(deposition_id: @previous_copy.deposition_id)
          else
            resp = @deposit.get_by_deposition(deposition_id: @previous_copy.deposition_id)
          end
        else
          resp = @deposit.new_deposition
        end
        @copy.update(deposition_id: resp[:id], software_doi: resp[:metadata][:prereserve_doi][:doi],
                          conceptrecid: resp[:conceptrecid] )

        # update metadata
        @deposit.update_metadata(doi: @copy.software_doi)

        # synchronize files
        @file_collection.synchronize_to_zenodo(bucket_url: resp[:links][:bucket])

        @copy.update(state: 'finished')
        @file_collection.cleanup_files # only cleanup files after success and finished, keep on fs so we have them otherwise
      rescue Stash::ZenodoReplicate::ZenodoError, HTTP::Error => ex
        @copy.update(state: 'error', error_info: "#{ex.class}\n#{ex}")
      end
      # rubocop:enable Metrics/MethodLength, Metrics/AbcSize, Metrics/CyclomaticComplexity

      private

      def error_if_any_previous_unfinished
        # items that don't have entries in the zenodo_copies table
        resources = @resource.identifier.resources
          .joins('LEFT JOIN stash_engine_zenodo_copies ON stash_engine_resources.id = stash_engine_zenodo_copies.resource_id')
          .where('stash_engine_zenodo_copies.resource_id IS NULL')

        return if resources.count < 1

        unsubmitted_count = resources.map{ |res| res.software_uploads.count }.reduce(0, :+)

        return unless unsubmitted_count.positive?

        raise ZE, "identifier_id #{@resource.identifier.id}: Cannot replicate a later version until earlier " \
              'versions with software have replicated. An earlier is missing from ZenodoCopies table.'
      end

      def error_if_more_than_one_replication_for_resource
        return if @resource.zenodo_copies.where(copy_type: 'software').count == 1 # can have software and software_publish for same resource
        raise ZE, "resource_id #{@resource.id}: Only one replication of the same type (software or data) is allowed per resource."
      end

      def files_changed?
        change_count = @resource.software_uploads.deleted_from_version.count + @resource.software_uploads.newly_created.count
        change_count.positive?
      end

      def nothing_to_submit?
        return false if submitted_before? || files_changed?

        @copy.update(state: 'finished', error_info: 'No software to submit to Zenodo for this resource id')
        true
      end

      def submitted_before?
        !@previous_copy.nil?
      end

      def previous_submission_published?
        return true if submitted_before? && @previous_copy.copy_type == 'software_publish'
        false
      end
    end
  end
end
