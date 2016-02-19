module StashEngine
  class Resource < ActiveRecord::Base
    has_many :file_uploads, class_name: 'StashEngine::FileUpload'
    has_and_belongs_to_many :subjects, class_name: 'StashDatacite::Subject'
  end
end
