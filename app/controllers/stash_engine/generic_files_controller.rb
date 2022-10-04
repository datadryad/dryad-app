require 'stash/aws/s3'
require 'aws-sdk-lambda'

module StashEngine
  class GenericFilesController < ApplicationController

    before_action :setup_class_info, :require_login
    before_action :set_file_info, only: %i[destroy_manifest]
    before_action :ajax_require_modifiable, only: %i[destroy_manifest validate_urls presign_upload upload_complete]

    helper_method :resource

    # this should be overridden for each specific type of file class
    def setup_class_info
      @file_model = nil
      @resource_assoc = :generic_files
    end

    # This used to be only for manifests, but now destroys both manifest and upload files
    def destroy_manifest
      respond_to do |format|
        format.html do
          @file.smart_destroy!
          render plain: 'OK'
        end
      end
    end

    # manifest workflow
    def validate_urls
      respond_to do |format|
        return unless resource

        url_param = params[:url]
        return if url_param.blank?

        url_errors = []
        urls_from(url_param).each do |url|
          result = create_upload(url)
          url_errors.push(result) if result[:status_code] != 200
        end
        format.html do
          render json: {
            # map(&:attributes): one way for translating ActiveRecord field type to json
            valid_urls: @resource.generic_files.validated_table.map(&:attributes),
            invalid_urls: url_errors
          }
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
        format.any(:json, :html) do
          # destroy any previous with this name and overwrite with this one
          @resource.send(@resource_assoc).where(upload_file_name: params[:name]).destroy_all

          db_file =
            @file_model.create(
              upload_file_name: params[:name],
              upload_content_type: params[:type],
              upload_file_size: params[:size],
              resource_id: @resource.id,
              upload_updated_at: Time.new,
              file_state: 'created',
              original_filename: params[:original]
            )

          render json: { new_file: db_file }
        end
      end
    end

    # this runs validation on all the files passed in as params['file_ids'], by calling lambda(s)
    # Not sure the reason for passing an array of ids since it's only one at a time, but maybe because of data
    # structures in the React code which seems a bit opaque
    # This is a POST request for multiple files and returns an array with triggered status (true/false)
    def trigger_frictionless
      # get scope of ALL tabular files from this resource
      tabular_files = resource.generic_files.tabular_files
      begin
        files = tabular_files.find(params['file_ids']) # narrow to just the file ids passed in
      rescue ActiveRecord::RecordNotFound => e
        puts "Record not found: #{e.inspect}" # only for rubocop
        render json: { status: "Couldn't find tabular file for this resource" }, status: :not_found
        return
      end

      files.each(&:set_checking_status) # set to checking status
      result = files.map do |f|
        result = f.trigger_frictionless
        f.frictionless_report.update(status: 'error', report: result[:msg]) if result[:triggered] == false
        { file_id: f.id, triggered: result[:triggered] }
      end

      render json: result
    end

    # takes a list of file IDs to check for frictionless reports, and returns only information on the completed
    # ones with non "checking" status
    # GET request
    def check_frictionless
      # get scope of ALL tabular files for the resource
      tabular_files = resource.generic_files.tabular_files
      begin
        files = tabular_files.find(params['file_ids']) # narrow to just the file ids passed in
      rescue ActiveRecord::RecordNotFound
        render json: { status: "Couldn't find some tabular files for this resource" }, status: :not_found
        return
      end

      files = files.select { |f| f&.frictionless_report&.report.present? && f&.frictionless_report&.status != 'checking' }

      render json: files.as_json(
        methods: :type, include: { frictionless_report: { only: %w[report status] } }
      )
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
      attributes = validator.upload_attributes_from(
        translator: url_translator, resource: resource, association: @resource_assoc
      )
      if attributes[:status_code] != 200
        { url: attributes[:url], status_code: attributes[:status_code] }
      else
        @file_model.create(attributes)
      end
    end

    def urls_from(url_param)
      url_param.split(/[\r\n]+/).map(&:strip).delete_if(&:blank?)
    end

    def set_file_info
      @file = @file_model.find(params[:id])
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
