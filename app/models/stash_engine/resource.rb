module StashEngine
  class Resource < ActiveRecord::Base
    has_many :file_uploads, :class_name => 'StashEngine::FileUpload'
  end
end
