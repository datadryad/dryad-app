# frozen_string_literal: true

# ATTENTION, we have both StashApi::File class (model) and the ruby File class, so be careful to namespace to avoid insanity

require 'fileutils'
require 'stash/aws/s3'
require 'stash/download/file_presigned'
require 'securerandom'

module StashApi
  class FilesController < ApiApplicationController
    include StashApi::FilesMixin

    before_action :require_json_headers, only: %i[show index destroy]
    before_action :force_json_content_type, except: :download
    before_action -> { require_resource_id(resource_id: params[:version_id]) }, only: [:index]
    before_action -> { require_file_id(file_id: params[:id]) }, only: %i[show destroy download]
    before_action -> { require_stash_identifier(doi: params[:id]) }, only: %i[update]
    before_action :doorkeeper_authorize!, only: %i[update destroy]
    before_action :require_api_user, only: %i[update destroy download]
    before_action :optional_api_user, except: %i[create update]
    before_action :require_in_progress_resource, only: %i[update]
    before_action :require_file_current_uploads, only: :update
    before_action :require_permission, only: %i[update destroy]
    before_action :require_viewable_file, only: %i[show download]
    before_action -> { require_viewable_resource(resource_id: params[:version_id]) }, only: :index
    before_action :set_download_service

    # GET /files/<id>
    def show
      file = StashApi::File.new(file_id: params[:id], user: @user)
      render json: file.metadata
    end

    # GET /files/digest/<digest>
    def digest
      files = StashEngine::DataFile.joins(:resource).where(resource: { file_view: true }, digest: params[:digest])
      paged = files.limit(per_page).offset(per_page * (page - 1)).map { |file| StashApi::File.new(file_id: file.id, user: @user).metadata }
      render json: files_output(files.count, paged)
    end

    # GET /versions/<version-id>/files
    def index
      files = paged_files_for_version
      render json: files
    end

    # PUT /datasets/<encoded-doi>/files/<encoded-file-name>
    def update
      # lots of checks and setup before creating the file (also see the before_actions above)
      pre_upload_checks { return }
      Stash::Aws::S3.new.put_stream(s3_key: @file_path, stream: request.body)
      after_upload_processing { return }
      file = StashApi::File.new(file_id: @file.id, user: @user)
      render json: file.metadata_with_url, status: 201
    end

    # DELETE /files/<id>
    def destroy
      unless @resource.current_state == 'in_progress'
        api_logger.error('version is not in_progress')
        render json: { error: 'This file must be part of an an in-progress version' }.to_json, status: 403
        return
      end
      file_hash = make_deleted(data_file: @stash_file)
      render json: file_hash, status: 200
    end

    # GET /files/<id>/download
    def download
      if @resource.may_download?(ui_user: @user)
        @file_presigned = Stash::Download::FilePresigned.new(controller_context: self)
        @file_presigned.download(file: @stash_file, from_api: true)
      else
        render status: 404, plain: 'Not found'
      end
    end

    private

    def paged_files_for_version
      resource = StashEngine::Resource.find(params[:version_id]) # version_id in the API is really resource_id in the database

      # If this resource is published, but its files are not publicly viewable,
      # the files haven't changed from the previous published version.
      # Find the most recent previous resource that had viewable files.
      if resource.current_curation_status == 'published' && !resource.file_view
        prev_resources = StashEngine::Resource.where(identifier_id: resource.identifier_id,
                                                     file_view: true,
                                                     id: 0..(resource.id - 1)).reverse
        resource = prev_resources.first unless prev_resources.blank?
      end

      visible = resource.data_files.present_files.order(download_filename: :asc)
      all_count = visible.count
      data_files = visible.limit(per_page).offset(per_page * (page - 1))
      results = data_files.map { |i| StashApi::File.new(file_id: i.id, user: @user).metadata }
      files_output(all_count, results)
    end

    def files_output(all_count, results)
      {
        '_links' => paging_hash(result_count: all_count),
        count: results.count,
        total: all_count,
        '_embedded' => { 'stash:files' => results }
      }
    end

    # make a file deleted and return the hash for what it looks like after with HATEOAS, I forgot this marks for deletion
    # also in second version
    def make_deleted(data_file:)
      case data_file.file_state
      when 'created' # delete from db since it's new in this version
        my_hate = { _links: StashApi::File.new(file_id: data_file.id).links.except(:self) }
        data_file.destroy
        return my_hate
      when 'copied' # make 'deleted' which will remove in this version on next submission
        data_file.update!(file_state: 'deleted')
      end
      StashApi::File.new(file_id: data_file.id).metadata_with_url
    end

    def require_viewable_file
      f = StashEngine::DataFile.where(id: params[:id]).first
      return unless f.nil? || !f.resource.may_view?(ui_user: @user)

      api_logger.error('require_viewable_file')
      render json: { error: 'not-found' }.to_json, status: 404
    end
  end
end
