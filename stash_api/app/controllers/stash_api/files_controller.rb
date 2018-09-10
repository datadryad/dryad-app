# frozen_string_literal: true

# ATTENTION, we have both StashApi::File class (model) and the ruby File class, so be careful to namespace to avoid insanity

require 'fileutils'

require_dependency 'stash_api/application_controller'

# rubocop:disable Metrics/ClassLength
module StashApi
  class FilesController < ApplicationController

    before_action -> { require_resource_id(resource_id: params[:version_id]) }, only: [:index]
    before_action -> { require_file_id(file_id: params[:id]) }, only: [:show]

    before_action -> { require_stash_identifier(doi: params[:id]) }, only: %i[update]
    before_action :doorkeeper_authorize!, only: :update
    before_action :require_api_user, only: :update
    before_action :require_in_progress_resource, only: :update
    before_action :require_permission, only: :update

    # GET /files/<id>
    def show
      file = StashApi::File.new(file_id: params[:id])
      respond_to do |format|
        format.json { render json: file.metadata }
        format.html { render text: UNACCEPTABLE_MSG, status: 406 }
      end
    end

    # GET /versions/<version-id>/files
    def index
      files = paged_files_for_version
      respond_to do |format|
        format.json { render json: files }
        format.html { render text: UNACCEPTABLE_MSG, status: 406 }
      end
    end

    # POST /versions/<version-id>/files/<encoded file name>
    def update
      # lots of checks and setup before creating the file (also see the before_actions above)
      pre_upload_checks { return }
      ::File.open(@file_path, 'wb') do |output_stream|
        IO.copy_stream(request.body, output_stream)
      end
      after_upload_processing { return }
      file = StashApi::File.new(file_id: @file.id)
      respond_to do |format|
        format.json { render json: file.metadata, status: 201 }
        format.html { render text: UNACCEPTABLE_MSG, status: 406 }
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

    def setup_file_path
      @file_path = ::File.expand_path(params[:filename], @resource.upload_dir)
      (render json: { error: 'No file shenanigans' }.to_json, status: 403) && yield unless @file_path.start_with?(@resource.upload_dir)
      FileUtils.mkdir_p(::File.dirname(@file_path))
    end

    def check_header_file_size
      return if request.headers['CONTENT-LENGTH'].blank? || request.headers['CONTENT-LENGTH'].to_i <= @resource.tenant.max_total_version_size
      (render json: { error:
                         "Your file size is larger than the maximum submission size of #{resource.tenant.max_total_version_size} bytes" }.to_json,
              status: 403) && yield
    end

    def check_file_size
      return if ::File.size(@file_path) <= @resource.tenant.max_total_version_size
      (render json: { error:
                          "Your file size is larger than the maximum submission size of #{resource.tenant.max_total_version_size} bytes" }.to_json,
              status: 403) && yield
    end

    # rubocop:disable Metrics/MethodLength
    def save_file_to_db
      just_user_fn = @file_path[@resource.upload_dir.length..-1].gsub(%r{^/+}, '') # just user fn and remove any leading slashes
      handle_previous_duplicates(upload_filename: just_user_fn)
      StashEngine::FileUpload.create(
        upload_file_name: just_user_fn,
        temp_file_path: @file_path,
        upload_content_type: request.headers['CONTENT-TYPE'],
        upload_file_size: ::File.size(@file_path),
        resource_id: @resource.id,
        upload_updated_at: Time.new.utc,
        file_state: 'created'
      )
    end
    # rubocop:enable Metrics/MethodLength

    def handle_previous_duplicates(upload_filename:)
      StashEngine::FileUpload.where(resource_id: @resource.id, upload_file_name: upload_filename).each do |file_upload|
        if file_upload.file_state == 'copied'
          file_upload.update(file_state: 'deleted')
        else
          file_upload.destroy!
        end
      end
    end

    def check_total_size_violations
      return if @resource.new_size <= @resource.tenant.max_total_version_size && @resource.size <= @resource.tenant.max_submission_size
      (render json: { error:
                          'The files for this dataset are larger than the allowed version or total object size' }.to_json,
              status: 403) && yield
    end

    def paged_files_for_version
      resource = StashEngine::Resource.find(params[:version_id]) # version_id is really resource_id
      visible = resource.file_uploads.present_files
      all_count = visible.count
      file_uploads = visible.limit(page_size).offset(page_size * (page - 1))
      results = file_uploads.map { |i| StashApi::File.new(file_id: i.id).metadata }
      files_output(all_count, results)
    end
    # rubocop:enable Metrics/AbcSize

    def files_output(all_count, results)
      {
        '_links' => paging_hash(result_count: all_count),
        count: results.count,
        total: all_count,
        '_embedded' => { 'stash:files' => results }
      }
    end
  end
end
# rubocop:enable Metrics/ClassLength
