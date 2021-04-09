require 'stash/aws/s3'

# rubocop:disable Metrics/ClassLength
module StashEngine
  class GenericFilesController < ApplicationController

    before_action :setup_class_info, :require_login
    before_action :set_file_info, only: %i[destroy destroy_error destroy_manifest]
    before_action :ajax_require_modifiable, only: %i[destroy_error destroy_manifest create validate_urls presign_upload upload_complete]

    helper_method :resource

    # this should be overridden for each specific type of file class
    def setup_class_info
      @file_model = nil
      @resource_assoc = :generic_files
    end

    # show the list of files for resource
    def index
      respond_to do |format|
        format.js do
          resource
          render 'stash_engine/data_files/index.js.erb'
        end
      end
    end

    # this seems to destroy a file that had an error?
    def destroy_error
      respond_to do |format|
        format.js do
          @url = @file.url
          @file.destroy
          render 'stash_engine/data_files/destroy_error.js.erb'
        end
      end
    end

    # This used to be only for manifests, but now destroys both manifest and upload files
    def destroy_manifest
      respond_to do |format|
        format.js do
          @file.smart_destroy!
          render 'stash_engine/data_files/destroy_manifest.js.erb'
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
        format.js do
          render 'stash_engine/data_files/validate_urls.js.erb'
        end
      end
    end

    # quick start guide for setup because the bucket needs to be set a certain way for CORS, also
    # https://github.com/TTLabs/EvaporateJS/wiki/Quick-Start-Guide
    #
    # This example based on https://github.com/TTLabs/EvaporateJS/blob/master/example/signing_example_awsv4_controller.rb
    def presign_upload
      render plain: hmac_data, status: :ok
    end

    def upload_complete
      respond_to do |format|
        format.json do
          # destroy any previous with this name and overwrite with this one
          @resource.send(@resource_assoc).where(upload_file_name: params[:name]).destroy_all

          _db_file =
            @file_model.create(
              upload_file_name: params[:name],
              upload_content_type: params[:type],
              upload_file_size: params[:size],
              resource_id: @resource.id,
              upload_updated_at: Time.new,
              file_state: 'created',
              original_filename: params[:original]
            )

          render json: { msg: 'ok' }
          # I tried code like this, but it always runs into some race condition and fails for large files
          # since I think Amazon hasn't assembled files from parts right away upon them completing in Evaporate.
          # unless Stash::Aws::S3.exists?(s3_key: db_file.calc_s3_path)
          #  db_file.destroy!
          #  render json: { msg: "bad upload at S3 for #{params[:name]}"}, status: :bad_request
          # end
        end
      end
    end

    # everything below this in the file is protected (accessible by the class and those that inherit from it)
    protected

    # set the resource correctly per action
    def resource
      @resource ||= if %w[destroy_error destroy_manifest].include?(params[:action])
                      @file_model.find(params[:id]).resource
                    else
                      Resource.find(params[:resource_id])
                    end
    end

    def create_upload(url)
      url_translator = Stash::UrlTranslator.new(url)
      validator = StashEngine::UrlValidator.new(url: url_translator.direct_download || url)
      @file_model.create(validator.upload_attributes_from(translator: url_translator, resource: resource, association: @resource_assoc))
    end

    def unique_upload_path(original_filename)
      filename = UrlValidator.make_unique(resource: resource, filename: original_filename, association: @resource_assoc)
      File.join(@upload_dir, filename)
    end

    def urls_from(url_param)
      url_param.split(/[\r\n]+/).map(&:strip).delete_if(&:blank?)
    end

    def set_file_info
      @file = @file_model.find(params[:id])
    end

    # Remove any unwanted characters from the uploaded file's name
    def sanitize_filename
      uploaded_file = params[:upload][:upload]
      return unless uploaded_file.is_a?(ActionDispatch::Http::UploadedFile)

      sanitized = @file_model.sanitize_file_name(uploaded_file.original_filename)
      @original_filename = uploaded_file.original_filename
      uploaded_file.original_filename = sanitized
    end

    def hmac_data
      aws_secret = APP_CONFIG[:s3][:secret]
      timestamp = params[:datetime]

      date = hmac("AWS4#{aws_secret}", timestamp[0..7])
      region = hmac(date, APP_CONFIG[:s3][:region])
      service = hmac(region, 's3')
      signing = hmac(service, 'aws4_request')

      hexhmac(signing, params[:to_sign])
    end

    def hmac(key, value)
      OpenSSL::HMAC.digest(OpenSSL::Digest.new('sha256'), key, value)
    end

    def hexhmac(key, value)
      OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha256'), key, value)
    end
  end
end
# rubocop:enable Metrics/ClassLength
