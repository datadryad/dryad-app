require_dependency 'stash_engine/application_controller'

module StashEngine
  class FileUploadsController < ApplicationController

    before_action :require_login

    before_action :set_file, only: [:destroy]

    before_action :require_file_owner, except: [ :create]


    def destroy
      respond_to do |format|
        logger.debug "in format"
        format.js {
          logger.debug "In format.js"
          File.delete(@file.temp_file_path) if File.exist?(@file.temp_file_path)
          @file_id = @file.id
          @file.destroy
        }
      end

    end

    def create
      respond_to do |format|
        format.js {
          @temp_id = params[:temp_id]
          fu = params[:upload][:upload]
          fn = FileUpload.new
          fn.upload_file_name = fu.original_filename
          fn.temp_file_path = fu.tempfile.path
          fn.upload_content_type = fu.content_type
          fn.upload_file_size = File.size(fu.tempfile.path)
          fn.resource_id = params[:resource_id]
          fn.upload_updated_at = Time.new
          fn.save
          @my_file = fn
        }
      end
    end

    private

    def require_file_owner
      logger.debug "current_user.id = #{current_user.id}"
      logger.debug "@file.resource.user_id = #{@file.resource.user_id}"
      logger.debug @file.resource.inspect
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
