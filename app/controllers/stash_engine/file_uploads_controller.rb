require_dependency 'stash_engine/application_controller'

module StashEngine
  class FileUploadsController < ApplicationController

    before_action :require_login

    before_action :set_file, only: [:edit, :update, :destroy]

    before_action :require_file_owner, except: [:index, :new, :create]

    def index
    end

    def new
    end

    def edit
    end

    def delete
    end

    def destroy
      respond_to do |format|
        format.js {
          File.delete(@file.temp_file_path) if File.exist?(@file.temp_file_path)
          @file_id = @file.id
          @file.destroy
        }
      end

    end

    def create
      respond_to do |format|
        format.js {
          fu = params[:upload][:upload]
          fn = FileUpload.new
          fn.upload_file_name = fu.original_filename
          fn.temp_file_path = fu.tempfile.path
          fn.upload_content_type = fu.content_type
          fn.upload_file_size = File.size(fu.tempfile.path)
          fn.resource_id = params[:file_upload][:resource_id]
          fn.upload_updated_at = Time.new
          fn.save
        }
      end
    end

    private

    def require_file_owner
      if current_user.id != @file.resource.user_id
        redirect_to tenants_path
        return false
      end
    end

    def set_file
      @file = FileUpload.find(params[:id])
    end
  end
end
