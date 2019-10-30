require_dependency 'stash_engine/application_controller'
require 'fileutils'
require 'stash/url_translator'

module StashEngine
  class FileUploadsController < ApplicationController # rubocop:disable Metrics/ClassLength
    before_action :require_login
    before_action :set_file_info, only: %i[destroy destroy_error destroy_manifest]
    before_action :ajax_require_modifiable, only: %i[destroy_error destroy_manifest create validate_urls]
    before_action :set_create_prerequisites, only: [:create]

    # attr_reader :resource
    helper_method :resource

    # show the list of files for resource
    def index
      respond_to do |format|
        format.js do
          resource
        end
      end
    end

    # this seems to destroy a file that had an error?
    def destroy_error
      respond_to do |format|
        format.js do
          @url = @file.url
          @file.destroy
        end
      end
    end

    # This used to be only for manifests, but now destroys both manifest and upload files
    def destroy_manifest
      respond_to do |format|
        format.js do
          @file.smart_destroy!
        end
      end
    end

    # a file being uploaded (chunk by chunk)
    def create
      respond_to do |format|
        format.js do
          add_to_file(@accum_file, @file_upload) # this accumulates bytes into file for chunked uploads
          if more_bytes_coming
            # do not render changes to page until full file uploads and is saved into db
            head :ok, content_type: 'application/javascript'
            return
          end
          @my_file = save_final_file
        end
      end
    end

    # manifest workflow
    def validate_urls
      respond_to do |format|
        return unless resource
        url_param = params[:url]
        return if url_param.blank?
        urls_from(url_param).each { |url| create_upload(url) }
        format.js
      end
    end

    private

    # set the resource correctly per action
    def resource
      @resource ||= if %w[destroy_error destroy_manifest].include?(params[:action])
                      FileUpload.find(params[:id]).resource
                    else
                      Resource.find(params[:resource_id])
                    end
    end

    def create_upload(url)
      url_translator = Stash::UrlTranslator.new(url)
      validator = StashEngine::UrlValidator.new(url: url_translator.direct_download || url)
      FileUpload.create(validator.upload_attributes_from(translator: url_translator, resource: resource))
    end

    def more_bytes_coming
      File.size(@accum_file) < params[:hidden_bytes].to_i
    end

    def save_final_file
      upload_path = unique_upload_path(@file_upload.original_filename)
      FileUtils.mv(@accum_file, upload_path)
      create_db_file(upload_path)
    end

    def unique_upload_path(original_filename)
      filename = UrlValidator.make_unique(resource: resource, filename: original_filename)
      File.join(@upload_dir, filename)
    end

    def urls_from(url_param)
      url_param.split(/[\r\n]+/).map(&:strip).delete_if(&:blank?)
    end

    def set_create_prerequisites
      sanitize_filename
      @temp_id = params[:temp_id]
      resource_id = params[:resource_id]
      upload_params = params[:upload]
      raise ActionController::RoutingError.new('Not Found'), 'Not Found' unless @temp_id && resource_id && upload_params
      ensure_upload_dir(resource_id)
      @accum_file = File.join(@upload_dir, @temp_id)
      @file_upload = upload_params[:upload]
    end

    def ensure_upload_dir(resource_id)
      @upload_dir = StashEngine::Resource.upload_dir_for(resource_id)
      FileUtils.mkdir_p @upload_dir unless File.exist?(@upload_dir)
    end

    def set_file_info
      @file = FileUpload.find(params[:id])
    end

    # write a chunk to the file.
    def add_to_file(fn, fileupload)
      File.open(fn, 'ab') { |f| f.write(fileupload.read) }
    end

    # for standard uploads, create standard file in DB, this only happens once a file upload is finished
    def create_db_file(path)
      # destroy any previous with this name and overwrite with this one
      @resource.file_uploads.where(upload_file_name: File.basename(path)).destroy_all
      FileUpload.create(
        upload_file_name: File.basename(path),
        temp_file_path: path,
        upload_content_type: @file_upload.content_type,
        upload_file_size: File.size(path),
        resource_id: params[:resource_id],
        upload_updated_at: Time.new.utc,
        file_state: 'created',
        original_filename: @original_filename || File.basename(path)
      )
    end

    # Remove any unwanted characters from the uploaded file's name
    def sanitize_filename
      uploaded_file = params[:upload][:upload]
      return unless uploaded_file.is_a?(ActionDispatch::Http::UploadedFile)
      sanitized = StashEngine::FileUpload.sanitize_file_name(uploaded_file.original_filename)
      @original_filename = uploaded_file.original_filename
      uploaded_file.original_filename = sanitized
    end

  end
end
