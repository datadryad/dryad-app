require_dependency 'stash_api/application_controller'

module StashApi
  class VersionsController < ApplicationController

    # get /versions/<id>
    def show
      v = Version.new(resource_id: params[:id])
      respond_to do |format|
        format.json { render json: v.metadata_with_links }
        format.html { render text: UNACCEPTABLE_MSG, status: 406 }
      end
    end

    # get /datasets/<dataset-id>/versions
    def index
      versions = paged_versions_for_dataset
      respond_to do |format|
        format.json { render json: versions }
        format.html { render text: UNACCEPTABLE_MSG, status: 406 }
      end
    end

    def paged_versions_for_dataset
      id = StashEngine::Identifier.find_with_id(params[:dataset_id])
      all_count = id.resources.count
      results = id.resources.limit(page_size).offset(page_size * (page - 1))
      results_count = results.count
      results = results.map { |i| Version.new(resource_id: i.id).metadata_with_links }
      {
        '_links' => paging_hash(result_count: all_count),
        count: results_count,
        total: all_count,
        '_embedded' => { 'stash:versions' => results }
      }
    end

  end
end
