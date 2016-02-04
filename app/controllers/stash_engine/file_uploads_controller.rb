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
      fu = params[:upload][:upload]
      fn = FileUpload.new
      fn.upload_file_name = fu.original_filename
      fn.temp_file_path = fu.tempfile.path
      fn.upload_content_type = fu.content_type
      fn.upload_file_size = File.size(fu.tempfile.path)
      fn.resource_id = params[:file_upload][:resource_id]
      fn.upload_updated_at = Time.new
      fn.save
    end
  end
end
