# frozen_string_literal: true

require 'fileutils'

require_dependency 'stash_api/application_controller'

module StashApi
  class FilesController < ApplicationController

    before_action -> { require_resource_id(resource_id: params[:version_id]) }, only: [:index]
    before_action -> { require_file_id(file_id: params[:id]) }, only: [:show]

    before_action -> { require_stash_identifier(doi: params[:id]) }, only: %i[create]
    before_action :doorkeeper_authorize!, only: :create
    before_action :require_api_user, only: :create
    before_action :require_in_progress_resource, only: :create

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
    def create
      # lots of checks and setup before creating the file (also see the before_actions above)
      setup_file_path { return } # wonky crap to make it return early if needed
      check_header_file_size { return }
      File.open(@file_path, 'wb') do |output_stream|
        IO.copy_stream(request.body, output_stream)
      end
      # now save it as a record in the database, including overwrites if needed
      puts request.headers['CONTENT-TYPE']
      puts request.headers['CONTENT-LENGTH']
    end

    private

    def setup_file_path
      @file_path = File.expand_path(params[:filename], @resource.upload_dir)
      (render json: { error: 'No file shenanigans' }.to_json, status: 403) && yield unless @file_path.start_with?(@resource.upload_dir)
      FileUtils.mkdir_p(File.dirname(@file_path))
    end

    # rubocop:disable Metrics/AbcSize
    def check_header_file_size
      return if request.headers['CONTENT-LENGTH'].blank? || request.headers['CONTENT-LENGTH'].to_i < @resource.tenant.max_total_version_size
      (render json: { error:
                         "Your file size is larger than the maximum submission size of #{resource.tenant.max_total_version_size} bytes" }.to_json,
              status: 403) && yield
    end
    # rubocop:enable Metrics/AbcSize

    # rubocop:disable Metrics/AbcSize
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
