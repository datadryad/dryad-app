# frozen_string_literal: true

# ATTENTION, we have both StashApi::File class (model) and the ruby File class, so be careful to namespace to avoid insanity

require 'fileutils'
require 'stash/aws/s3'
require 'stash/download/file_presigned'

module StashApi
  class FilesController < ApiApplicationController

    before_action :require_json_headers, only: %i[show index destroy]
    before_action :force_json_content_type, except: :download
    before_action -> { require_resource_id(resource_id: params[:version_id]) }, only: [:index]
    before_action -> { require_file_id(file_id: params[:id]) }, only: %i[show destroy download]
    before_action -> { require_stash_identifier(doi: params[:id]) }, only: %i[update]
    before_action :doorkeeper_authorize!, only: %i[update destroy]
    before_action :require_api_user, only: %i[update destroy]
    before_action :optional_api_user, except: %i[create update]
    before_action :require_in_progress_resource, only: %i[update]
    before_action :require_file_current_uploads, only: :update
    before_action :require_permission, only: %i[update destroy]
    before_action :require_viewable_file, only: %i[show download]
    before_action -> { require_viewable_resource(resource_id: params[:version_id]) }, only: :index

    # GET /files/<id>
    def show
      file = StashApi::File.new(file_id: params[:id])
      render json: file.metadata
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
      Stash::Aws::S3.put_stream(s3_key: @file_path, stream: request.body)
      after_upload_processing { return }
      file = StashApi::File.new(file_id: @file.id)
      render json: file.metadata, status: 201
    end

    # DELETE /files/<id>
    def destroy
      unless @resource.current_state == 'in_progress'
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
        StashEngine::CounterLogger.general_hit(request: request, file: @stash_file)
        @file_presigned.download(file: @stash_file)
      else
        render status: 404, plain: 'Not found'
      end
    end

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
      @file_path = "#{@resource.s3_dir_name(type: 'data')}/#{@sanitized_name}"
    end

    # prevent people from sending bad filenames
    def sanitize_filename(filename)
      @original_filename = filename
      # TODO: replace with GenericFile?
      StashEngine::DataFile.sanitize_file_name(filename)
    end

    # only allow to proceed if no other current uploads or only other url-type uploads
    def require_file_current_uploads
      the_type = @resource.upload_type
      return if %i[files unknown].include?(the_type)

      render json: { error:
          'You may not submit a file by direct upload in the same version when you have submitted files by URL' }.to_json, status: 409
    end

    def check_header_file_size
      return if request.headers['CONTENT-LENGTH'].blank? || request.headers['CONTENT-LENGTH'].to_i <= APP_CONFIG.maximums.merritt_size

      (render json: { error:
                         "Your file size is larger than the maximum submission size of #{APP_CONFIG.maximums.merritt_size} bytes" }.to_json,
              status: 403) && yield
    end

    def check_file_size
      return if Stash::Aws::S3.size(s3_key: @file_path) <= APP_CONFIG.maximums.merritt_size

      (render json: { error:
          "Your file size is larger than the maximum submission size of #{view_context.filesize(APP_CONFIG.maximums.merritt_size)}" }.to_json,
              status: 403) && yield
    end

    def save_file_to_db
      handle_previous_duplicates(upload_filename: @sanitized_name)
      file = StashEngine::DataFile.create(
        upload_file_name: @sanitized_name,
        upload_content_type: file_content_type,
        upload_file_size: Stash::Aws::S3.size(s3_key: @file_path),
        resource_id: @resource.id,
        upload_updated_at: Time.new.utc,
        file_state: 'created',
        description: request.env['HTTP_CONTENT_DESCRIPTION'],
        original_filename: @original_filename || @sanitized_name
      )
      @resource.update(
        total_file_size: StashEngine::DataFile.where(resource_id: @resource.id).where(file_state: %w[created copied]).sum(:upload_file_size)
      )
      file
    end

    def file_content_type
      type = request.headers['CONTENT-TYPE']
      type = 'application/octet-stream' unless type.present?
      type
    end

    def handle_previous_duplicates(upload_filename:)
      StashEngine::DataFile.where(resource_id: @resource.id, upload_file_name: upload_filename).each do |data_file|
        if data_file.file_state == 'copied'
          data_file.update(file_state: 'deleted')
        else
          data_file.destroy!
        end
      end
    end

    def check_total_size_violations
      return if @resource.new_size <= APP_CONFIG.maximums.merritt_size && @resource.size <= APP_CONFIG.maximums.merritt_size

      (render json: { error:
                          'The files for this dataset are larger than the allowed version or total object size' }.to_json,
              status: 403) && yield
    end

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

      visible = resource.data_files.present_files
      all_count = visible.count
      data_files = visible.limit(per_page).offset(per_page * (page - 1))
      results = data_files.map { |i| StashApi::File.new(file_id: i.id).metadata }
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
      StashApi::File.new(file_id: data_file.id).metadata
    end

    def require_viewable_file
      f = StashEngine::DataFile.where(id: params[:id]).first
      render json: { error: 'not-found' }.to_json, status: 404 if f.nil? || !f.resource.may_view?(ui_user: @user)
    end
  end
end
