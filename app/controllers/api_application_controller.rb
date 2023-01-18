# frozen_string_literal: true

require 'url_pager'
require 'cgi'

# class ApplicationController < ActionController::Base
class ApiApplicationController < StashEngine::ApplicationController

  layout 'layouts/stash_engine/application'

  skip_before_action :verify_authenticity_token

  DEFAULT_PAGE_SIZE = 20
  UNACCEPTABLE_MSG = '406 - unacceptable: please set your Content-Type and Accept headers for application/json'

  def page
    @page ||= (params[:page].to_i.positive? ? params[:page].to_i : 1)
  end

  def per_page
    [params['per_page']&.to_i || DEFAULT_PAGE_SIZE, 100].min
  end

  def paging_hash(result_count:)
    up = UrlPager.new(current_url: request.original_url, result_count: result_count, current_page: page, page_size: per_page)
    up.paging_hash
  end

  def require_json_headers
    accept = request.headers['accept']
    content_type = request.headers['content-type']
    # check that content_type and accept headers are as expected
    ct_ok = content_type.nil? || content_type.start_with?('application/json')
    accept_ok = accept.nil? || (accept.include?('*/*') || accept.include?('application/json'))
    return if ct_ok && accept_ok

    render json: { error: UNACCEPTABLE_MSG }.to_json, status: 406
  end

  def require_stash_identifier(doi:)
    # check to see if the identifier is actually an id and not a DOI first
    @stash_identifier = StashEngine::Identifier.where(id: doi).first
    @stash_identifier = StashEngine::Identifier.find_with_id(doi) if @stash_identifier.blank?
    render json: { error: 'not-found' }.to_json, status: 404 if @stash_identifier.blank?
  end

  def require_resource_id(resource_id:)
    @stash_resources = StashEngine::Resource.where(id: resource_id)
    @resource = @stash_resources&.first if @stash_resources.count.positive?
    render json: { error: 'not-found' }.to_json, status: 404 if @stash_resources.count < 1
  end

  def require_file_id(file_id:)
    @stash_files = StashEngine::DataFile.where(id: file_id)
    if @stash_files.count < 1
      render json: { error: 'not-found' }.to_json, status: 404
    else
      @stash_file = @stash_files.first
      @resource = @stash_file.resource # for require_permission to use
    end
  end

  def require_api_user
    optional_api_user
    render json: { error: 'Unauthorized, must have current bearer token' }.to_json, status: 401 if @user.blank?
  end

  def optional_api_user
    @user = nil
    # the user we're operating for varies depending on the grant type.
    return unless doorkeeper_token

    @user = if doorkeeper_token.resource_owner_id.present?
              # Authorization Code Grant
              user = StashEngine::User.where(id: doorkeeper_token.resource_owner_id).first
              # set user role to 'user' for this request (without saving to db) since people doing proxy edits for a
              # user's data don't get special curator/admin/superuser permissions
              if user.present?
                user.role = 'user'
                user
              end
            else
              # Client Credentials Grant type
              doorkeeper_token.application.owner
            end
  end

  def require_in_progress_resource
    unless @stash_identifier.in_progress?
      render json: { error: 'You must have an in_progress version to perform this operation' }.to_json, status: 403
    end
    @resource = @stash_identifier.in_progress_resource
  end

  def require_viewable_resource(resource_id:)
    res = StashEngine::Resource.where(id: resource_id).first
    render json: { error: 'not-found' }.to_json, status: 404 if res.nil? || !res.may_view?(ui_user: @user)
  end

  # based on user and resource set in "require_api_user" and 'require_resource_in_progress'
  def require_permission
    return if @resource.nil? # this not needed for dataset upsert with identifier

    render json: { error: 'unauthorized' }.to_json, status: 401 unless @resource.permission_to_edit?(user: @user)
  end

  def require_superuser
    return if @user.superuser?

    render json: { error: 'unauthorized' }.to_json, status: 401
  end

  def require_curator
    return if @user.curator?

    render json: { error: 'unauthorized' }.to_json, status: 401
  end

  def require_admin
    return if %w[superuser curator admin tenant_curator].include?(@user.role) ||
              @user.journals_as_admin.present?

    render json: { error: 'unauthorized' }.to_json, status: 401
  end

  # call this like return_error(messages: 'blah', status: 400) { yield }
  def return_error(messages:, status:)
    if messages.instance_of?(String)
      (render json: { error: messages }.to_json, status: status) && yield
    elsif messages.instance_of?(Array)
      (render json: messages.map { |e| { error: e } }.to_json, status: status) && yield
    end
  end

  def force_json_content_type
    response.headers['Content-Type'] = 'application/json; charset=utf-8'
  end
end
