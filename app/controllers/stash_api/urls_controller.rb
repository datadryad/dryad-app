require 'api_application_controller'
require 'fileutils'
require 'stash/url_translator'

module StashApi
  class UrlsController < ApiApplicationController

    before_action :require_json_headers
    before_action :force_json_content_type
    before_action -> { require_stash_identifier(doi: params[:dataset_id]) }, only: %i[create]
    before_action :doorkeeper_authorize!, only: :create
    before_action :require_api_user, only: :create
    before_action :require_in_progress_resource, only: :create
    before_action :require_url_current_uploads, only: :create
    before_action :require_permission, only: :create
    before_action :require_correctly_formatted_url, only: :create

    # POST '/datasets/:dataset_id/urls'
    def create
      data_file_hash = if params['skipValidation'] == true
                         skipped_validation_hash(params) { return } # return will be yielded to if error is rendered, so it returns here
                       else
                         validate_url(params[:url]) { return }
                       end
      validate_digest_type { return }

      # merge additional params as translated from API (value) to database field (key)
      { digest_type: :digestType, upload_file_name: :path, upload_content_type: :mimeType, digest: :digest, description: :description }.each do |k, v|
        data_file_hash[k] = params[v] if params[v]
      end

      fu = StashEngine::DataFile.create(data_file_hash)
      check_file_size(data_file: fu) { return }
      file = StashApi::File.new(file_id: fu.id) # parse file display object
      render json: file.metadata, status: 201
    end

    private

    def validate_url(url)
      url_translator = Stash::UrlTranslator.new(url)
      validator = StashEngine::UrlValidator.new(url: url_translator.direct_download || url)
      validation_hash = validator.upload_attributes_from(translator: url_translator, resource: @resource, association: 'data_files')
      (render json: { error: 'The URL you are adding already exists.' }.to_json, status: 403) && yield if validation_hash[:status_code] == 409
      (render json: { error: 'Socket, connection or response error.' }.to_json, status: 403) && yield if validation_hash[:status_code] == 499
      unless validation_hash[:status_code].between?(200, 299)
        (render json: { error:
                            "An error occurred validating your url with http status code #{validation_hash[:status_code]}" }.to_json,
                status: 403) && yield
      end
      validation_hash
    end

    def skipped_validation_hash(_hsh)
      unless params[:size] && params[:mimeType] && params[:url]
        (render json: { error: 'You must supply a size, mimetype and url.' }.to_json, status: 403) && yield
      end
      if @resource.url_in_version?(association: 'generic_files', url: params[:url])
        (render json: { error: 'You have already supplied this url' }.to_json, status: 403) && yield
      end
      my_path = params[:path] || ::File.basename(URI.parse(params[:url]).path)
      (render json: { error: 'You must supply a path (filename) for this url' }.to_json, status: 403) && yield if my_path.blank?
      { resource_id: @resource.id, url: params[:url], status_code: 200, file_state: 'created',
        upload_file_name: my_path, upload_content_type: params[:mimeType], upload_file_size: params[:size] }
    end

    def require_correctly_formatted_url
      (render json: { error: 'The URL you supplied is invalid.' }.to_json, status: 403) unless correctly_formatted_url?(params[:url])
    end

    def correctly_formatted_url?(url)
      u = URI.parse(url)
      u.is_a?(URI::HTTP)
    rescue URI::InvalidURIError
      false
    end

    def check_file_size(data_file:)
      return if @resource.size <= APP_CONFIG.maximums.merritt_size

      data_file.destroy # because this item won't fit
      (render json: { error:
                          'This file would make your submission size larger than the maximum of ' \
                          "#{view_context.filesize(APP_CONFIG.maximums.merritt_size)}" }.to_json, status: 403) && yield
    end

    # only allow to proceed if no other current uploads or only other url-type uploads
    def require_url_current_uploads
      the_type = @resource.upload_type
      return if %i[manifest unknown].include?(the_type)

      render json: { error: 'You may not submit a URL in the same version when you have submitted files by direct file upload' }.to_json, status: 409
    end

    def validate_digest_type
      digest_types = StashEngine::DataFile.digest_types.keys
      return if params[:digestType].nil? || digest_types.include?(params[:digestType])

      (render json: { error:
          "digestType should be one of the values in this list: #{digest_types.join(', ')}" }.to_json, status: 403) && yield
    end

  end
end
