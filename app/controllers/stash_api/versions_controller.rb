# frozen_string_literal: true

module StashApi
  class VersionsController < ApiApplicationController
    include Downloadable

    before_action :require_json_headers, only: %i[show index]
    before_action :force_json_content_type, except: :download
    before_action -> { require_stash_identifier(doi: params[:dataset_id]) }, only: [:index]
    before_action -> { require_resource_id(resource_id: params[:id]) }, only: %i[show download]
    before_action :optional_api_user
    before_action -> { require_viewable_resource(resource_id: params[:id]) }, only: :show

    # get /versions/<id>
    def show
      v = Version.new(resource_id: params[:id], item_view: true)
      render json: v.metadata_with_links
      res = @stash_resources.first
      StashEngine::CounterLogger.general_hit(request: request, resource: res) if res
    end

    # get /datasets/<dataset-id>/versions
    def index
      versions = paged_versions_for_dataset
      render json: versions
    end

    # get /versions/<id>/download
    def download
      if @stash_resources.length == 1
        res = @stash_resources.first
        @zip_version_presigned = Stash::Download::ZipVersionPresigned.new(controller_context: self, resource: res)
        if res&.may_download?(ui_user: @user) && @zip_version_presigned.valid_resource?
          StashEngine::CounterLogger.version_download_hit(request: request, resource: res)
          @zip_version_presigned.download(resource: res)
        else
          render plain: 'Download for this version of the dataset is unavailable', status: 404
        end
      else
        render plain: 'not found', status: 404
      end
    end

    # get /versions/<id>/zip_assembly
    def zip_assembly
      @resource = StashEngine::Resource.find(params[:id])
      info = @resource.data_files.present_files.map do |f|
        {
          size: f.upload_file_size,
          filename: f.upload_file_name,
          url: f.s3_permanent_presigned_url
        }
      end
      render json: info
    end

    private

    def paged_versions_for_dataset
      id = StashEngine::Identifier.find_with_id(params[:dataset_id])
      limited_resources = StashEngine::ResourcePolicy::VersionScope.new(@user, id.resources).resolve
      all_count = limited_resources.count
      results = limited_resources.limit(per_page).offset(per_page * (page - 1))
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

  end
end
