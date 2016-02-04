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
      byebug
      fu = params[:upload][:upload]
      file = FileUpload.new
      file.upload_file_name = fu.original_filename
      file.temp_file_path = fu.tempfile.path
      file.upload_content_type = fu.content_type
      file.upload_file_size = File.size(fu.tempfile.path)
      file.resource_id = params[:file_upload][:resource_id]
      file.save
    end
  end
end
