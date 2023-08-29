require 'stash/zenodo_replicate'
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
      def initialize(resource:, zc_id:)
        # gets filenames for items already in Zenodo
        @zc_id = zc_id
        resp = ZC.standard_request(:get, "#{ZC.base_url}/api/deposit/depositions/#{resource.zenodo_copies.data.first.deposition_id}",
                                   zc_id: @zc_id)
        @existing_zenodo_filenames = resp[:files].map { |f| f[:filename] }
        @resource = resource
      end

      # list of file objects to upload
      def upload_list
        return @resource.data_files.present_files unless published_previously?

        # upload anything that has changed since last publish or anything that doesn't exist in Zenodo's files
        ppr = previous_published_resource

        # anything that was submitted since the last publish
        changed = StashEngine::DataFile
          .joins(:resource)
          .where('stash_engine_resources.identifier_id = ?', @resource.identifier_id)
          .where('stash_engine_generic_files.resource_id > ? AND stash_engine_generic_files.resource_id <= ?', ppr.id, @resource.id)
          .where("file_state = 'created' OR file_state IS NULL").distinct.pluck(:upload_file_name)

        # this will pick up any missing files that we have locally, but not on zenodo, may be required for old datasets that
        # have been published before, but never had files sent to zenodo because we weren't sending old datasets
        not_in_zenodo = StashEngine::DataFile
          .where(resource_id: @resource.id)
          .present_files
          .where.not(upload_file_name: @existing_zenodo_filenames).distinct.pluck(:upload_file_name)

        # and limit to only items that still exist in the current version: eliminates duplicates and recently deleted files
        @resource.data_files.where(upload_file_name: (changed + not_in_zenodo)).present_files
      end

      # list of filenames for deletion from zenodo
      def delete_list
        return [] unless published_previously?

        # existing zenodo filenames on Zenodo server minus current existing database filenames leaves the ones to delete
        @existing_zenodo_filenames - @resource.data_files.present_files.distinct.pluck(:upload_file_name)
      end

      def published_previously?
        previous_published_resource.present?
      end

      def previous_published_resource
        # sometimes it's just easier to drop to SQL with a complex query, subquery limits to the last curation status
        # for each resource and then limits to the published last statuses by joining another copy of table with only published items
        query = <<~SQL.chomp
          SELECT res.* FROM stash_engine_resources res
          JOIN stash_engine_curation_activities cur1
            ON res.last_curation_activity_id  = cur1.id
          WHERE cur1.status = 'published'
            AND res.identifier_id = ?
            AND res.id < ?
          ORDER BY res.id DESC;
        SQL
        StashEngine::Resource.find_by_sql([query, @resource.identifier_id, @resource.id]).first
      end

    end
  end
end
