# frozen_string_literal: true

require_dependency 'stash_api/application_controller'
require 'stash/download/version'

module StashApi
  class VersionsController < ApplicationController

    before_action :require_json_headers, only: %i[show index]
    before_action -> { require_stash_identifier(doi: params[:dataset_id]) }, only: [:index]
    before_action -> { require_resource_id(resource_id: params[:id]) }, only: %i[show download]
    before_action :optional_api_user
    before_action :require_viewable_resource, only: :show

    # get /versions/<id>
    def show
      v = Version.new(resource_id: params[:id])
      respond_to do |format|
        format.json { render json: v.metadata_with_links }
        res = @stash_resources.first
        StashEngine::CounterLogger.general_hit(request: request, resource: res) if res
      end
    end

    # get /datasets/<dataset-id>/versions
    def index
      versions = paged_versions_for_dataset
      respond_to do |format|
        format.json { render json: versions }
      end
    end

    # get /versions/<id>/download
    def download
      @version_streamer = Stash::Download::Version.new(controller_context: self)
      if @stash_resources.length == 1
        res = @stash_resources.first
        if res.may_download?(ui_user: @user)
          @version_streamer.download(resource: res) do
            redirect_to stash_url_helpers.landing_show_path(id: res.identifier_str, big: 'showme') # if it's an async
          end
        else
          render text: 'forbidden', status: 403
        end
      else
        render text: 'download for this version is unavailable', status: 404
      end
    end

    private

    def paged_versions_for_dataset
      id = StashEngine::Identifier.find_with_id(params[:dataset_id])
      limited_resources = id.resources.visible_to_user(user: @user)
      all_count = limited_resources.count
      results = limited_resources.limit(page_size).offset(page_size * (page - 1))
      results = results.map { |i| Version.new(resource_id: i.id).metadata_with_links }
      page_output(all_count, results)
    end

    def page_output(all_count, results)
      {
        '_links' => paging_hash(result_count: all_count),
        count: results.count,
        total: all_count,
        '_embedded' => { 'stash:versions' => results }
      }
    end

    def require_viewable_resource
      res = StashEngine::Resource.where(id: params[:id]).first
      render json: { error: 'not-found' }.to_json, status: 404 if res.nil? || !res.may_view?(ui_user: @user)
    end
  end
end
