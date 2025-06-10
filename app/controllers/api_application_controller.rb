# frozen_string_literal: true

require 'url_pager'
require 'cgi'

# class ApplicationController < ActionController::Base
class ApiApplicationController < StashEngine::ApplicationController
  include StashApi::Versioning

  layout 'layouts/stash_engine/application'

  before_action :log_request
  before_action :set_response_version_header
  before_action :check_requested_version
  skip_before_action :verify_authenticity_token

  rescue_from(*StashApi::Error::RESCUABLE_EXCEPTIONS) do |err|
    err_klass = err.class
    response_status = 500
    object = err

    if err_klass == ActiveRecord::RecordInvalid
      object = err.record
      response_status = 422
    elsif err_klass == ActiveRecord::RecordNotFound
      response_status = 404
    elsif err_klass <= StashApi::SafeError
      response_status = err.http_status
    elsif err_klass <= Exception
      if Rails.env.development? || Rails.env.test?
        logger.error(err.message)
        logger.error(err.backtrace.join("\n "))
      end

      # TODO: hook into bugsnag when we get to it
      # Bugsnag.notify(err)
      object = StashApi::Error::ServerError.new(err.message, original: err)
    end

    # TODO: update error messages that are returned by pundit
    #       https://github.com/elabs/pundit#creating-custom-error-messages
    render json: { error: StashApi::Error::Render.from(object).first&.message }, status: response_status
  end

  def page
    @page ||= (params[:page].respond_to?(:to_i) && params[:page].to_i.positive? ? params[:page].to_i : 1)
  end

  def per_page
    [params[:per_page]&.to_i || DEFAULT_PAGE_SIZE, 100].min
  end

  def paging_hash(result_count:)
    up = UrlPager.new(current_url: request.original_url, result_count: result_count, current_page: page, page_size: per_page)
    up.paging_hash
  end

  def require_json_headers
    request.format = :json unless params[:format]

    accept = request.headers['accept']
    content_type = request.headers['content-type']
    # check that content_type and accept headers are as expected
    ct_ok = content_type.nil? || content_type.start_with?('application/json')
    accept_ok = accept.nil? || (accept.include?('*/*') || accept.include?('application/json'))
    return if ct_ok && accept_ok

    api_logger.error('require_json_headers')
    render json: { error: 'not-acceptable' }.to_json, status: 406
  end

  def require_stash_identifier(doi:)
    # check to see if the identifier is actually an id and not a DOI first
    @stash_identifier = StashEngine::Identifier.where(id: doi).first
    @stash_identifier ||= StashEngine::Identifier.find_with_id(doi)

    return if @stash_identifier.present?

    api_logger.error('require_stash_identifier')
    render json: { error: 'not-found' }.to_json, status: 404
  end

  def require_resource_id(resource_id:)
    @stash_resources = StashEngine::Resource.where(id: resource_id)
    @resource = @stash_resources&.first if @stash_resources.count.positive?

    return unless @stash_resources.count < 1

    api_logger.error('require_resource_id')
    render json: { error: 'not-found' }.to_json, status: 404
  end

  def require_file_id(file_id:)
    @stash_files = StashEngine::DataFile.where(id: file_id)
    if @stash_files.count < 1
      api_logger.error('require_file_id')
      render json: { error: 'not-found' }.to_json, status: 404
    else
      @stash_file = @stash_files.first
      @resource = @stash_file.resource # for require_permission to use
    end
  end

  def require_api_user
    optional_api_user
    return unless @user.blank?

    api_logger.error('require_api_user')
    render json: { error: 'Unauthorized, must have current bearer token' }.to_json, status: 401
  end

  def optional_api_user
    @user = nil
    # the user we're operating for varies depending on the grant type.
    return unless doorkeeper_token

    @user = if doorkeeper_token.resource_owner_id.present?
              # Authorization Code Grant
              # Roleless user for API proxy
              StashEngine::ProxyUser.where(id: doorkeeper_token.resource_owner_id).first
            else
              # Client Credentials Grant type
              doorkeeper_token.application.owner
            end

    logger.info("User: #{@user&.id}")
  end

  def require_in_progress_resource
    unless @stash_identifier.in_progress?
      api_logger.error('require_in_progress_resource')
      render json: { error: 'You must have an in_progress version to perform this operation' }.to_json, status: 403
    end
    @resource = @stash_identifier.in_progress_resource
  end

  def require_viewable_resource(resource_id:)
    res = StashEngine::Resource.where(id: resource_id).first
    api_logger.error('require_viewable_resource')
    render json: { error: 'not-found' }.to_json, status: 404 if res.nil? || !res.may_view?(ui_user: @user)
  end

  # based on user and resource set in "require_api_user" and 'require_resource_in_progress'
  def require_permission
    return if @resource.nil? # this not needed for dataset upsert with identifier
    return if @resource.permission_to_edit?(user: @user)

    api_logger.error('require_permission')
    render json: { error: 'unauthorized' }.to_json, status: 401
  end

  def require_superuser
    return if @user.superuser?

    api_logger.error('require_superuser')
    render json: { error: 'unauthorized' }.to_json, status: 401
  end

  def require_min_app_admin
    return if @user.min_app_admin?

    api_logger.error('require_min_app_admin')
    render json: { error: 'unauthorized' }.to_json, status: 401
  end

  def require_curator
    return if @user.min_curator?

    api_logger.error('require_curator')
    render json: { error: 'unauthorized' }.to_json, status: 401
  end

  def require_admin
    return if current_user && current_user.min_admin?

    api_logger.error('require_admin')
    render json: { error: 'unauthorized' }.to_json, status: 401
  end

  # call this like return_error(messages: 'blah', status: 400) { yield }
  def return_error(messages:, status:)
    if messages.instance_of?(String)
      api_logger.error("Status: #{status} Message: #{messages}")
      (render json: { error: messages }.to_json, status: status) && yield
    elsif messages.instance_of?(Array)
      api_logger.error("Status: #{status} Message: #{messages.map { |e| { error: e } }.to_json}")
      (render json: messages.map { |e| { error: e } }.to_json, status: status) && yield
    end
  end

  def force_json_content_type
    response.headers['Content-Type'] = 'application/json; charset=utf-8'
  end

  def api_logger
    Rails.application.config.api_logger
  end

  def log_request
    api_logger.info('---')
    api_logger.info("Path: #{request.path}")
    api_logger.info("Params: #{request.params}")
    api_logger.info("Body: #{request.body}")
  end
end
