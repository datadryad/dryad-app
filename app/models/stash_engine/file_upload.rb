module StashEngine
  class FileUpload < ActiveRecord::Base
    belongs_to :resource, :class_name => 'StashEngine::Resource'
    mount_uploader :upload_file_name, FileUploader

  end
end
