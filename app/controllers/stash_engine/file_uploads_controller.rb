require_dependency 'stash_engine/application_controller'
require 'fileutils'

module StashEngine
  class FileUploadsController < ApplicationController
    before_action :require_login

    before_action :set_file_info, only: [:destroy, :remove, :restore]

    before_action :require_file_owner, except: [:create, :destroy, :remove, :restore]

    before_action :set_create_prerequisites, only: [:create]

    def destroy
      respond_to do |format|
        format.js do
          File.delete(@file.temp_file_path) if File.exist?(@file.temp_file_path)
          @file_id = @file.id
          @file.destroy
        end
      end
    end

    def remove
      respond_to do |format|
        format.js do
          @file.update_attribute(:file_state, 'deleted') # This because carrierwave interferes with something not its business
          @file.reload
        end
      end
    end

    def restore
      respond_to do |format|
        format.js do
          @file.update_attribute(:file_state, 'copied') # This because carrierwave interferes with something not its business
          @file.reload
        end
      end
    end


    def create
      respond_to do |format|
        format.js do
          add_to_file(@accum_file, @file_upload) # this accumulates bytes into file for chunked uploads

          if File.size(@accum_file) < params[:hidden_bytes].to_i
            # do not render changes to page until full file uploads and is saved into db
            head :ok, content_type: 'application/javascript'
            return
          end

          new_fn = File.join(@upload_dir, @file_upload.original_filename)
          FileUtils.mv(@accum_file, new_fn)

          @my_file = FileUpload.new(
            upload_file_name: @file_upload.original_filename,
            temp_file_path: new_fn,
            upload_content_type: @file_upload.content_type,
            upload_file_size: File.size(new_fn),
            resource_id: params[:resource_id],
            upload_updated_at: Time.new.utc,
            file_state: 'created')
          @my_file.save
        end
      end
    end

    private

    def require_file_owner
      return if current_user.id == @file.resource.user_id
      redirect_to tenants_path && return
    end

    def set_create_prerequisites
      unless params[:resource_id] && params[:temp_id] && params[:upload]
        raise ActionController::RoutingError.new('Not Found'), 'Not Found'
      end
      @upload_dir = File.join(Rails.root, 'uploads', params[:resource_id])
      @temp_id = params[:temp_id]
      FileUtils.mkdir_p @upload_dir unless File.exist?(@upload_dir)
      @accum_file = File.join(@upload_dir, @temp_id)
      @file_upload = params[:upload][:upload]
    end

    def set_file_info
      @file = FileUpload.find(params[:id])
    end

    def add_to_file(fn, fileupload)
      File.open(fn, 'ab') { |f| f.write(fileupload.read) }
    end
  end
end
