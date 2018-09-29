require_dependency 'stash_api/application_controller'
require 'fileutils'
require 'stash/url_translator'
module StashApi
  class UrlsController < ApplicationController

    before_action -> { require_stash_identifier(doi: params[:dataset_id]) }, only: %i[create]
    before_action :doorkeeper_authorize!, only: :create
    before_action :require_api_user, only: :create
    before_action :require_in_progress_resource, only: :create
    before_action :require_permission, only: :create
    before_action :require_correctly_formatted_url, only: :create

    # { url: 'https://crackpot.com',
    #   skipValidation: true/false (only available to superusers),
    #   if not validated then the following items need to be supplied
    #   path: 'Overview.html',
    #   size: 18288,
    #   mimeType: 'application/pdf' }
    # rubocop:disable Metrics/MethodLength
    def create
      file_upload_hash = if params['skipValidation'] == true
                           skipped_validation_hash(params) { return }
                         else
                           validate_url(params[:url]) { return } # return will be called if rendered and error and yielded: no double-rendering
                         end
      # TODO: check over total size or over file size allowed
      fu = StashEngine::FileUpload.create(file_upload_hash)
      file = StashApi::File.new(file_id: fu.id)
      respond_to do |format|
        format.json { render json: file.metadata, status: 201 }
        format.html { render text: UNACCEPTABLE_MSG, status: 406 }
      end
    end
    # rubocop:enable Metrics/MethodLength

    private

    # rubocop:disable Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
    def validate_url(url)
      url_translator = Stash::UrlTranslator.new(url)
      validator = StashEngine::UrlValidator.new(url: url_translator.direct_download || url)
      validation_hash = validator.upload_attributes_from(translator: url_translator, resource: @resource)
      (render json: { error: 'The URL you are adding already exists.' }.to_json, status: 403) && yield if validation_hash[:status_code] == 409
      (render json: { error: 'Socket, connection or response error.' }.to_json, status: 403) && yield if validation_hash[:status_code] == 499
      unless validation_hash[:status_code].between?(200, 299)
        (render json: { error:
                            "An error occurred validating your file with http status code #{validation_hash[:status_code]}" }.to_json,
                status: 403) && yield
      end
      validation_hash
    end
    # rubocop:enable Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity

    # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    def skipped_validation_hash(_hsh)
      unless params[:size] && params[:mimeType] && params[:url]
        (render json: { error: 'You must supply a size, mimetype and url.' }.to_json, status: 403) && yield
      end
      (render json: { error: 'You have already supplied this url' }.to_json, status: 403) && yield if @resource.url_in_version?(params[:url])
      my_path = params[:path] || ::File.basename(URI.parse(params[:url]).path)
      (render json: { error: 'You must supply a path (filename) for this url' }.to_json, status: 403) && yield if my_path.blank?
      { resource_id: @resource.id, url: params[:url], status_code: 200, file_state: 'created',
        upload_file_name: my_path, upload_content_type: params[:mimeType], upload_file_size: params[:size] }
    end
    # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

    def require_correctly_formatted_url
      (render json: { error: 'The URL you supplied is invalid.' }.to_json, status: 403) unless correctly_formatted_url?(params[:url])
    end

    def correctly_formatted_url?(url)
      u = URI.parse(url)
      u.is_a?(URI::HTTP)
    rescue URI::InvalidURIError
      false
    end

  end
end
