# frozen_string_literal: true

# ATTENTION, we have both StashApi::File class (model) and the ruby File class, so be careful to namespace to avoid insanity

require 'fileutils'

require_dependency 'stash_api/application_controller'

# rubocop:disable Metrics/ClassLength
module StashApi
  class FilesController < ApplicationController

    before_action :require_json_headers, only: %i[show index destroy]
    before_action -> { require_resource_id(resource_id: params[:version_id]) }, only: [:index]
    before_action -> { require_file_id(file_id: params[:id]) }, only: %i[show destroy]

    before_action -> { require_stash_identifier(doi: params[:id]) }, only: %i[update]
    before_action :doorkeeper_authorize!, only: %i[update destroy]
    before_action :require_api_user, only: %i[update destroy]
    before_action :optional_api_user, except: %i[create update]
    before_action :require_in_progress_resource, only: %i[update]
    before_action :require_file_current_uploads, only: :update
    before_action :require_permission, only: %i[update destroy]
    before_action :require_viewable_file, only: :show
    before_action -> { require_viewable_resource(resource_id: params[:version_id]) }, only: :index

    # GET /files/<id>
    def show
      file = StashApi::File.new(file_id: params[:id])
      respond_to do |format|
        format.json { render json: file.metadata }
      end
    end

    # GET /versions/<version-id>/files
    def index
      files = paged_files_for_version
      respond_to do |format|
        format.json { render json: files }
      end
    end

    # PUT /datasets/<encoded-doi>/files/<encoded-file-name>
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
      end
    end

    # DELETE /files/<id>
    # has set @stash_file and @resource and checked user would be able to edit this resource (permission), but not that it's in-progress
    # HATEOAS seems to allow a response with links and other fun stuff.
    def destroy
      unless @resource.current_state == 'in_progress'
        render json: { error: 'This file must be part of an an in-progress version' }.to_json, status: 403
        return
      end
      file_hash = make_deleted(file_upload: @stash_file)
      respond_to do |format|
        format.json { render json: file_hash, status: 200 }
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
      @sanitized = sanitize_filename(params[:filename])
      @file_path = ::File.expand_path(@sanitized, @resource.upload_dir)
      (render json: { error: 'No file shenanigans' }.to_json, status: 403) && yield unless @file_path.start_with?(@resource.upload_dir)
      FileUtils.mkdir_p(::File.dirname(@file_path))
    end

    # prevent people from sending bad filenames
    def sanitize_filename(filename)
      @original_filename = filename
      StashEngine::FileUpload.sanitize_file_name(filename)
    end

    # only allow to proceed if no other current uploads or only other url-type uploads
    def require_file_current_uploads
      the_type = @resource.upload_type
      return if %i[files unknown].include?(the_type)
      render json: { error:
          'You may not submit a file by direct upload in the same version when you have submitted files by URL' }.to_json, status: 409
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
          "Your file size is larger than the maximum submission size of #{view_context.filesize(resource.tenant.max_total_version_size)}" }.to_json,
              status: 403) && yield
    end

    def save_file_to_db
      md5 = Digest::MD5.file(@file_path).hexdigest
      just_user_fn = @file_path[@resource.upload_dir.length..-1].gsub(%r{^/+}, '') # just user fn and remove any leading slashes
      handle_previous_duplicates(upload_filename: just_user_fn)
      StashEngine::FileUpload.create(
        upload_file_name: @sanitized,
        temp_file_path: @file_path,
        upload_content_type: request.headers['CONTENT-TYPE'],
        upload_file_size: ::File.size(@file_path),
        resource_id: @resource.id,
        upload_updated_at: Time.new.utc,
        file_state: 'created',
        digest: md5,
        digest_type: 'md5',
        description: request.env['HTTP_CONTENT_DESCRIPTION'],
        original_filename: @original_filename || just_user_fn
      )
    end

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

    def files_output(all_count, results)
      {
        '_links' => paging_hash(result_count: all_count),
        count: results.count,
        total: all_count,
        '_embedded' => { 'stash:files' => results }
      }
    end

    # make a file deleted and return the hash for what it looks like after with HATEOAS
    def make_deleted(file_upload:)
      case file_upload.file_state
      when 'created' # delete from db since it's new in this version
        my_hate = { '_links': StashApi::File.new(file_id: file_upload.id).links.except(:self) }
        file_upload.destroy
        return my_hate
      when 'copied' # make 'deleted' which will remove in this version on next submission
        file_upload.update!(file_state: 'deleted')
      end
      StashApi::File.new(file_id: file_upload.id).metadata
    end

    def require_viewable_file
      f = StashEngine::FileUpload.where(id: params[:id]).first
      render json: { error: 'not-found' }.to_json, status: 404 if f.nil? || !f.resource.may_view?(ui_user: @user)
    end
  end
end
# rubocop:enable Metrics/ClassLength
