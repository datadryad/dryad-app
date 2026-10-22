module StashApi
  class FileUploadsController < ApiApplicationController
    include StashApi::FilesMixin

    before_action :set_user
    before_action :load_upload, only: %i[part_url complete abort]
    before_action :force_json_content_type
    before_action -> { require_stash_identifier(doi: params[:doi]) }
    before_action :doorkeeper_authorize!
    before_action :require_in_progress_resource
    before_action :require_file_current_uploads
    before_action :require_permission
    before_action :set_download_service

    BUCKET = APP_CONFIG[:s3][:bucket]
    MAX_PARTS = 10_000

    def start
      pre_upload_checks { true }
      @file = save_file_to_db(file_state: 'uploading', upload_file_size: 0)
      check_total_size_violations(size: request.headers['CONTENT-LENGTH'].to_i) { yield }

      s3_upload_id = s3.create_multipart_upload(
        bucket: BUCKET, key: @file_path, content_type: 'application/octet-stream'
      ).upload_id

      upload = FileUpload.create!(
        user_id: @user.id,
        key: @file_path,
        upload_id: s3_upload_id,
        status: 'pending',
        resource_id: @resource.id,
        file_id: @file.id
      )
      render json: { id: upload.id }
    end

    def part_url
      n = params.require(:part_number).to_i
      return head :unprocessable_entity unless (1..MAX_PARTS).cover?(n)

      url = presigner.presigned_url(
        :upload_part,
        bucket: BUCKET, key: @upload.key, upload_id: @upload.upload_id,
        part_number: n, expires_in: 1.hour.to_i
      )
      FileUpload.find(params[:id]).update!(part_number: params[:part_number])
      render json: { url: url }
    end

    def complete
      parts = params.require(:parts).map { |p| p.permit(:etag, :part_number).to_h.symbolize_keys }
      parts = parts.map { |p| { etag: p[:etag], part_number: p[:part_number].to_i } }
        .sort_by { |p| p[:part_number] }

      s3.complete_multipart_upload(
        bucket: BUCKET, key: @upload.key, upload_id: @upload.upload_id,
        multipart_upload: { parts: parts }
      )

      # Read file size from S3
      size = s3.head_object(bucket: BUCKET, key: @upload.key).content_length

      file = @upload.file
      file.update(file_state: 'created', upload_file_size: size)
      @upload.update!(status: 'complete', size: size)

      result = StashApi::File.new(file_id: file.id, user: @user)
      render json: result.metadata_with_url, status: 201
    end

    def abort
      s3.abort_multipart_upload(bucket: BUCKET, key: @upload.key, upload_id: @upload.upload_id)
      @upload.update!(status: 'aborted')
      head :no_content
    end

    private

    def set_user
      if doorkeeper_token
        @user = doorkeeper_token.application.owner
        # Only check token expiration on upload start
        # To avoid an upload failing because of a token expiring in the middle of a large file transfer
        if params[:action] == 'start' && doorkeeper_token.expired?
          api_logger.error('require_api_user')
          AuthFailureService.new(request, @user.id, params).create(:api_expired_token)
          render json: { error: 'Token expired' }.to_json, status: 401 and return
        end
        return
      end

      api_logger.error('require_api_user')
      log_unauthorized_access(message: 'Unauthorized')
    end

    def load_upload
      @upload = FileUpload.find_by!(id: params[:id], status: 'pending')
    end

    def s3
      @s3 ||= Aws::S3::Client.new
    end

    def presigner
      @presigner ||= Aws::S3::Presigner.new(client: s3)
    end
  end
end
