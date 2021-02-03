require_dependency 'stash_engine/application_controller'

module StashEngine
  class TestUploadsController < ApplicationController
    before_action :require_login, only: %i[index]
    before_action :ajax_require_current_user, only: %i[presign_upload complete]

    # GET /tenants
    def index
      if params[:id].nil?
        render plain: 'This page requires ?id=<resource-id>', status: :ok
        return
      end

      @resource = Resource.find(params[:id])
    end

    # POST
    def complete
      resource = Resource.find(params[:resource_id])
      # params[:name], params[:size], params[:type]

      fu = FileUpload.where(upload_file_name: params[:name], resource_id: resource.id).first
      fu = FileUpload.new if fu.nil?

      # if something was copied from previous version and uploaded again then delete previous and create new
      if fu.file_state == 'copied'
        fu.update(file_state: 'deleted')
        fu = FileUpload.new
      end

      fu.update( upload_file_name: params[:name],
                 upload_content_type: params[:type],
                 upload_file_size: params[:size],
                 resource_id: resource.id,
                 upload_updated_at: Time.new,
                 file_state: 'created',
                 original_filename: params[:name] )

      respond_to do |format|
        format.json { render :json => {msg: "ok"} }
      end
    end

    # quick start guide for setup because the bucket needs to be set a certain way for CORS, also
    # https://github.com/TTLabs/EvaporateJS/wiki/Quick-Start-Guide
    #
    # This example based on https://github.com/TTLabs/EvaporateJS/blob/master/example/signing_example_awsv4_controller.rb
    def presign_upload
      render plain: hmac_data, status: :ok
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

    private

    def hmac(key, value)
      OpenSSL::HMAC.digest(OpenSSL::Digest.new('sha256'), key, value)
    end

    def hexhmac(key, value)
      OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha256'), key, value)
    end
  end
end
