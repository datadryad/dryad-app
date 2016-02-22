module StashEngine
  class Resource < ActiveRecord::Base
    has_many :file_uploads, class_name: 'StashEngine::FileUpload'
    has_and_belongs_to_many :subjects, class_name: 'StashDatacite::Subject'

    #StashEngine.belong_to_resource.each do |i|
    #  has_many i.downcase, class_name: "#{}::"
    #end

    # clean up the uploads with files that no longer exist for this resource
    def clean_uploads
      file_uploads.each do |fu|
        fu.destroy unless File.exist?(fu.temp_file_path)
      end
    end
  end
end
