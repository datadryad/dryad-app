require 'erb'
require 'stash/zenodo_software' # for pre-release software downloads

module StashEngine
  class SoftwareUpload < ActiveRecord::Base
    # self.table_name = 'stash_engine_software_uploads'
    belongs_to :resource, class_name: 'StashEngine::Resource'

    include StashEngine::Concerns::ModelUploadable

    def calc_s3_path
      return nil if file_state == 'copied' || file_state == 'deleted' # no current file to have a path for

      "#{resource.s3_dir_name(type: 'software')}/#{upload_file_name}"
    end

    def public_zenodo_download_url
      copy = ZenodoCopy.where(resource_id: resource_id, copy_type: 'software_publish').last
      return '#' if copy.nil? || copy.deposition_id.nil? || copy.state != 'finished' || file_state == 'deleted'

      "#{APP_CONFIG[:zenodo][:base_url]}/record/#{copy.deposition_id}/files/#{ERB::Util.url_encode(upload_file_name)}?download=1"
    end

    def zenodo_presigned_url
      rat = Stash::ZenodoSoftware::RemoteAccessToken.new(zenodo_config: APP_CONFIG.zenodo)
      dep_id = resource.zenodo_copies.software&.last&.deposition_id
      raise "Zenodo presigned downloads must have deposition ids for resource #{resource.id}" if dep_id.blank?

      rat.magic_url(deposition_id: dep_id, filename: upload_file_name)
    end

  end
end
