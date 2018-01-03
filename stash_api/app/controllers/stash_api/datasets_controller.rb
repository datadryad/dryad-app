require_dependency 'stash_api/application_controller'

module StashApi
  class DatasetsController < ApplicationController

    before_action only: [:show] { require_stash_identifier(doi: params[:id]) }

    # get /datasets/<id>
    def show
      ds = Dataset.new(identifier: @stash_identifier.to_s)
      respond_to do |format|
        format.json { render json: ds.metadata }
        format.xml { render xml: ds.metadata.to_xml(root: 'dataset') }
        format.html { render text: UNACCEPTABLE_MSG, status: 406 }
      end
    end

    # get /datasets
    def index
      datasets = paged_datasets
      respond_to do |format|
        format.json { render json: datasets }
        format.xml { render xml: datasets.to_xml(root: 'datasets') }
        format.html { render text: UNACCEPTABLE_MSG, status: 406 }
      end
    end

    private

    def all_datasets
      { 'stash:datasets' =>
          StashEngine::Identifier.all.map { |i| Dataset.new(identifier: "#{i.identifier_type}:#{i.identifier}").metadata } }
    end

    def paged_datasets
      all_count = StashEngine::Identifier.all.count
      results = StashEngine::Identifier.all.limit(page_size).offset(page_size * (page - 1))
      results_count = results.count
      results = results.map { |i| Dataset.new(identifier: "#{i.identifier_type}:#{i.identifier}").metadata }
      {
        '_links' => paging_hash(result_count: all_count),
        count: results_count,
        total: all_count,
        '_embedded' => { 'stash:datasets' => results }
      }
    end

  end
end
