require_dependency 'stash_engine/application_controller'

module StashEngine
  class FileUploadsController < ApplicationController
    def index
    end

    def new
    end

    def edit
    end

    def delete
    end

    def create
      fu = params[:file_upload]
      file = FileUpload.new
      file.upload_file_name = fu[:upload_file_name].original_filename
      file.temp_file_path = fu[:upload_file_name].tempfile.path
      file.upload_content_type = fu[:upload_file_name].content_type
      file.upload_file_size = File.size(file.temp_file_name)
      file.resource_id = params[:resource_id]
      file.save
      redi
    end
  end
end
