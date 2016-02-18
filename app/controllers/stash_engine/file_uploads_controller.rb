require_dependency 'stash_engine/application_controller'

module StashEngine
  class FileUploadsController < ApplicationController
    before_action :require_login

    before_action :set_file, only: [:destroy]

    before_action :require_file_owner, except: [:create]

    def destroy
      respond_to do |format|
        format.js do
          File.delete(@file.temp_file_path) if File.exist?(@file.temp_file_path)
          @file_id = @file.id
          @file.destroy
        end
      end
    end

    def create
      respond_to do |format|
        format.js do
          @temp_id = params[:temp_id]
          fu = params[:upload][:upload]
          @my_file = FileUpload.new(
            upload_file_name: fu.original_filename,
            temp_file_path: fu.tempfile.path,
            upload_content_type: fu.content_type,
            upload_file_size: File.size(fu.tempfile.path),
            resource_id: params[:resource_id],
            upload_updated_at: Time.new)
          @my_file.save
        end
      end
    end

    private

    def require_file_owner
      return if current_user.id = @file.resource.user_id
      redirect_to tenants_path && return
    end

    def set_file
      @file = FileUpload.find(params[:id])
    end
  end
end
