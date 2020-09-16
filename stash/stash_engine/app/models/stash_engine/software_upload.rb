require 'erb'

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

    def public_zenodo_download_url
      copy = ZenodoCopy.where(resource_id: resource_id, copy_type: 'software_publish').last
      return '#' if copy.nil? || copy.deposition_id.nil? || copy.state != 'finished' || file_state == 'deleted'

      "#{APP_CONFIG[:zenodo][:base_url]}/record/#{copy.deposition_id}/files/#{ERB::Util.url_encode(upload_file_name)}?download=1"
    end

  end
end
