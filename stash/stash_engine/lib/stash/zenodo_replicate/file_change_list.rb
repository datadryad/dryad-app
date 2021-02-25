require 'stash/zenodo_replicate/zenodo_connection'

module Stash
  module ZenodoReplicate
    class FileChangeList

      ZC = Stash::ZenodoReplicate::ZenodoConnection # keep code shorter with this

      def initialize(resource:, existing_zenodo_filenames:)


        # gets filenames for items already in Zenodo
        @existing_zenodo_filenames = existing_zenodo_filenames

        @resource = resource
      end

      # list of file objects to upload
      def upload_list
        return @resource.file_uploads.present_files unless published_previously?

        # upload anything that has changed since last publish or anything that doesn't exist in Zenodo's files
        ppr = previous_published_resource

        # anything that has had any changes since last publication
        changed = StashEngine::FileUpload
          .joins(:resource)
          .where("stash_engine_resources.identifier_id = ?", @resource.identifier_id)
          .where("stash_engine_file_uploads.resource_id > ? AND stash_engine_file_uploads.resource_id <= ?", ppr.id, @resource.id)
          .where("file_state = 'created' OR file_state IS NULL OR file_state = 'deleted'")

        not_in_zenodo = StashEngine::FileUpload
          .where(resource_id: @resource.id)
          .where.not(upload_file_name: @existing_zenodo_filenames)

        # changed and not in zenodo
        to_upload = (changed + not_in_zenodo).map(&:upload_file_name).uniq

        # and in the current file list
        @resource.file_uploads.where(upload_file_name: to_upload).present_files
      end

      # list of filenames for deletion from zenodo
      def delete_list
        return [] unless published_previously?

        # existing zenodo filenames minus current existing database filenames leaves the ones to delete
        @existing_zenodo_filenames - @resource.file_uploads.present_files.map(&:upload_file_name)
      end

      def published_previously?
        previous_published_resource.empty?
      end

      def previous_published_resource
        StashEngine::Resource.where("id < ?", @resource.id).
          where("publication_date != ? AND publication_date IS NOT NULL", @resource.publication_date)
      end

    end
  end
end
