module StashEngine
  class SoftwareUpload < ActiveRecord::Base
    # self.table_name = 'stash_engine_software_uploads'
    belongs_to :resource, class_name: 'StashEngine::Resource'

    include StashEngine::Concerns::ModelUploadable

    def calc_file_path
      return nil if file_state == 'copied' || file_state == 'deleted' # no current file to have a path for

      # the uploads directory is well defined so we can calculate it and don't need to store it
      File.join(Resource.software_upload_dir_for(resource_id), upload_file_name).to_s
    end

  end
end
