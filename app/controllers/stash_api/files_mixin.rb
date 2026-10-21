module StashApi
  module FilesMixin

    private

    def pre_upload_checks
      setup_file_path { yield }
      check_header_file_size { yield }
    end

    def after_upload_processing
      check_file_size { yield }
      @file = save_file_to_db
      check_total_size_violations { yield }
    end

    # prevent people doing badness like filenames like ../../../foobar
    def setup_file_path
      @sanitized_name = sanitize_filename(params[:filename])
      @uuid = "#{SecureRandom.uuid}#{::File.extname(@sanitized_name)}"
      @file_path = "#{@resource.s3_dir_name(type: 'data')}/#{@uuid}"
    end

    # prevent people from sending bad filenames
    def sanitize_filename(filename)
      @original_filename = filename
      file_name = StashEngine::FilenameSanitizer.new(filename).process
      # TODO: replace with GenericFile?
      StashEngine::DataFile.sanitize_file_name(file_name)
    end

    def check_header_file_size
      return if request.headers['CONTENT-LENGTH'].blank? || request.headers['CONTENT-LENGTH'].to_i <= APP_CONFIG.maximums.merritt_size

      api_logger.error('file too large')
      (render json: { error:
                        "Your file size is larger than the maximum submission size of #{APP_CONFIG.maximums.merritt_size} bytes" }.to_json,
              status: 403) && yield
    end

    def check_file_size
      return if Stash::Aws::S3.new.size(s3_key: @file_path) <= APP_CONFIG.maximums.merritt_size

      api_logger.error('file too large')
      (render json: {
        error: "Your file size is larger than the maximum submission size of #{view_context.filesize(APP_CONFIG.maximums.merritt_size)}"
      }.to_json,
              status: 403) && yield
    end

    def save_file_to_db(upload_file_size:, file_state: 'created')
      handle_previous_duplicates(upload_filename: @sanitized_name)
      file_params = {
        download_filename: @sanitized_name,
        upload_file_name: @uuid,
        upload_content_type: file_content_type,
        upload_file_size: upload_file_size || Stash::Aws::S3.new.size(s3_key: @file_path),
        description: request.env['HTTP_CONTENT_DESCRIPTION'],
        original_filename: @original_filename || @sanitized_name
      }
      StashEngine::FileUploadService.new(resource: @resource, file_params: file_params, file_state: file_state).save
    end

    def file_content_type
      type = request.headers['CONTENT-TYPE']
      type = 'application/octet-stream' unless type.present?
      type
    end

    def handle_previous_duplicates(upload_filename:)
      StashEngine::DataFile.where(resource_id: @resource.id, download_filename: upload_filename).each do |data_file|
        if data_file.file_state == 'copied'
          data_file.update(file_state: 'deleted')
        else
          data_file.destroy!
        end
      end
    end

    def check_total_size_violations(size:)
      size ||= @resource.new_size
      return if size <= APP_CONFIG.maximums.merritt_size && @resource.size <= APP_CONFIG.maximums.merritt_size

      api_logger.error('file too large')
      (render json: { error:
                        'The files for this dataset are larger than the allowed version or total object size' }.to_json,
              status: 403) && yield
    end

  end
end
