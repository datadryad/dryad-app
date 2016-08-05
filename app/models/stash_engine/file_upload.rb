module StashEngine
  class FileUpload < ActiveRecord::Base
    belongs_to :resource, class_name: 'StashEngine::Resource'
    # mount_uploader :uploader, FileUploader # it seems like maybe I don't need this since I'm doing so much manually

    enum file_state: ['created', 'copied', 'deleted'].map{|i| [i.to_sym, i]}.to_h
  end
end
