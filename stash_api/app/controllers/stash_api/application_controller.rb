# frozen_string_literal: true

require 'url_pager'
require 'cgi'

module StashApi
  # class ApplicationController < ActionController::Base
  class ApplicationController < ::StashEngine::ApplicationController

    layout 'layouts/stash_engine/application'

    skip_before_action :verify_authenticity_token

    PAGE_SIZE = 10

    UNACCEPTABLE_MSG = '406 - unacceptable: please set your Content-Type and Accept headers for application/json'

    def page
      @page ||= (params[:page].to_i.positive? ? params[:page].to_i : 1)
    end

    def page_size
      PAGE_SIZE
    end

    def paging_hash(result_count:)
      up = UrlPager.new(current_url: request.original_url, result_count: result_count, current_page: page, page_size: page_size)
      up.paging_hash
    end

    def require_json_headers
      accept = request.headers['accept']
      return if request.headers['content-type'] == 'application/json' && (accept.include?('*/*') || accept.include?('application/json'))
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
      render json: { error: 'not-found' }.to_json, status: 404 if @stash_resources.count < 1
    end

    def require_file_id(file_id:)
      @stash_files = StashEngine::FileUpload.where(id: file_id)
      render json: { error: 'not-found' }.to_json, status: 404 if @stash_files.count < 1
    end

    def require_api_user
      @user = doorkeeper_token.application.owner if doorkeeper_token
      render json: { error: 'Unauthorized, must have current bearer token' }.to_json, status: 401 if @user.blank?
    end

    def require_in_progress_resource
      unless @stash_identifier.in_progress?
        render json: { error: 'You must have an in_progress version to perform this operation' }.to_json, status: 403
      end
      @resource = @stash_identifier.in_progress_resource
    end

    # based on user and resource set in "require_api_user" and 'require_resource_in_progress'
    def require_permission
      return if @resource.nil? # this not needed for dataset upsert with identifier
      render json: { error: 'unauthorized' }.to_json, status: 401 unless @resource.can_edit?(user: @user)
    end

    def require_superuser
      return if @user.role == 'superuser'
      render json: { error: 'unauthorized' }.to_json, status: 401
    end

    def require_curator
      return if @user.role == 'superuser'
      render json: { error: 'unauthorized' }.to_json, status: 401
    end

    # call this like return_error(messages: 'blah', status: 400) { yield }
    def return_error(messages:, status:)
      if messages.class == String
        (render json: { error: messages }.to_json, status: status) && yield
      elsif messages.class == Array
        (render json: messages.map { |e| { error: e } }.to_json, status: status) && yield
      end
    end

  end
end
