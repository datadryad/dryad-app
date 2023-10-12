require 'stash/s3_download'
require 'http'
require 'stash/zenodo_replicate'
require 'stash/zenodo_replicate/copier_mixin'
require 'stash/zenodo_software/file_collection'

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

      # This is just a convenience method for manually testing without going through delayed_job, but is useful
      # as a utility manually submit and debug errors.
      # It adds all entries for submitting in the zenodo_copies table as needed, and resets if needed to test again.
      # Though the resource you're using should be submitted to Merritt already
      def self.test_submit(resource_id:)
        rep_type = 'data'
        resource = StashEngine::Resource.find(resource_id)
        zc = StashEngine::ZenodoCopy.where(resource_id: resource.id).where(copy_type: rep_type).first
        if zc.nil?
          zc = StashEngine::ZenodoCopy.create(state: 'enqueued', identifier_id: resource.identifier_id,
                                              resource_id: resource.id, copy_type: rep_type)
        elsif zc.state != 'enqueued'
          zc.update(state: 'enqueued')
        end
        zen_soft_res = Stash::ZenodoReplicate::Copier.new(copy_id: zc.id)
        zen_soft_res.add_to_zenodo
      end

      def initialize(copy_id:)
        @dataset_type = :data
        @copy = StashEngine::ZenodoCopy.find(copy_id)
        @previous_copy = StashEngine::ZenodoCopy.where(identifier_id: @copy.identifier_id).where('id < ? ', @copy.id)
          .data.order(id: :desc).first
        @resource = StashEngine::Resource.find(@copy.resource_id)
      end

      def add_to_zenodo
        # sanity checks
        error_if_over_50gb # these error eventually and interfere with other jobs, so for now this is here
        error_if_not_enqueued
        error_if_replicating
        error_if_out_of_order

        @copy.reload
        @copy.update(state: 'replicating')
        @copy.increment!(:retries)

        # a zenodo deposit class for working with deposits
        @deposit = Stash::ZenodoReplicate::Deposit.new(resource: @resource, zc_id: @copy.id)

        # get/create the deposit(ion) from zenodo
        get_or_create_deposition
        @copy.reload
        @copy.update(deposition_id: @deposit.deposition_id)

        # update metadata and get response which has info links in it
        @resp = @deposit.update_metadata

        # update files
        file_change_list = FileChangeList.new(resource: @resource, zc_id: @copy.id)
        @file_collection = Stash::ZenodoSoftware::FileCollection.new(file_change_list_obj: file_change_list, zc_id: @copy.id)
        @file_collection.synchronize_to_zenodo(bucket_url: @resp[:links][:bucket])

        # submit it, publishing will fail if there isn't at least one file
        @deposit.publish
        @copy.reload
        @copy.update(state: 'finished')
      rescue Stash::S3Download::DownloadError, Stash::ZenodoReplicate::ZenodoError, HTTP::Error => e
        # log this in the database so we can track it
        @copy.reload
        error_info = "#{Time.new} #{e.class}\n#{e}\n---\n#{@copy.error_info}" # append current error info first
        @copy.update(state: 'error', error_info: error_info)
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

      def previous_deposition_id
        return @copy.deposition_id unless @copy.deposition_id.blank?

        return @previous_copy.deposition_id unless @previous_copy.nil?

        nil
      end
    end
  end
end
