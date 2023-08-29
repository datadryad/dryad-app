require 'stash/zenodo_replicate'

module Stash
  module ZenodoSoftware
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

      def initialize(resource:, resource_method:)
        @resource_method = resource_method
        @resource = resource
      end

      # list of file objects to upload
      def upload_list
        @resource.send(@resource_method).newly_created
      end

      # list of filenames for deletion from zenodo
      def delete_list
        @resource.send(@resource_method).deleted_from_version.pluck(:upload_file_name)
      end
    end
  end
end
