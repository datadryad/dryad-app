require 'stash/zenodo_replicate/zenodo_connection'
require 'stash/zenodo_software/file_collection'

module Stash
  module ZenodoReplicate
    class FileChangeList

      ZC = Stash::ZenodoReplicate::ZenodoConnection # keep code shorter with this

      # This is a duck-type interface for creating lists of what gets uploaded and deleted from Zenodo.
      # To use it, please create a class for your replication strategy that implements two
      # methods:
      #  - upload_list (the database object list of files to be uploaded to zenodo for this update)
      #  - delete_list (the list of filenames-only to be removed from zenodo for this update)
      #
      # Then instantiate that class with appropriate information and pass it to the FileCollection class
      # and it will use these two methods to push the appropriate changes you to Zenodo.
      #
      # The lists are quite different for software (and similar) vs "3rd copies".  Software is updated/staged
      # to zenodo with each version a user submits and then publication is a separate action.
      #
      # "3rd copies" are only updated upon publication and there may be one to many version changes to data files
      # since the last publication.  While we could just update every file with every publication, it would be
      # slower and use more upload time and bandwidth.  Ideally, we should just update any files that have changed
      # since our last publication, add any files that don't exist at Zenodo and remove any files that no longer exist
      # in our data and leave the rest of the files that stayed the same alone.
      def initialize(resource:)
        # gets filenames for items already in Zenodo
        resp = ZC.standard_request(:get, "#{ZC.base_url}/api/deposit/depositions/#{resource.zenodo_copies.data.first.deposition_id}")
        @existing_zenodo_filenames = resp[:files].map { |f| f[:filename] }

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
        previous_published_resource.present?
      end

      def previous_published_resource
        StashEngine::Resource.where("id < ?", @resource.id).
          where("publication_date != ? AND publication_date IS NOT NULL", @resource.publication_date)
      end

    end
  end
end
