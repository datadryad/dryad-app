module StashEngine
  class FileUpload < ActiveRecord::Base
    belongs_to :resource, class_name: 'StashEngine::Resource', dependent: :destroy
    # mount_uploader :uploader, FileUploader # it seems like maybe I don't need this since I'm doing so much manually

    scope :deleted_from_version, -> { where(file_state: :deleted) }
    scope :newly_created, -> { where("file_state = 'created' OR file_state IS NULL") }
    enum file_state: ['created', 'copied', 'deleted'].map{|i| [i.to_sym, i]}.to_h
  end
end
