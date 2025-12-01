class LatestController < ApplicationController
  helper StashEngine::ApplicationHelper
  include StashEngine::SharedController
  skip_before_action :verify_authenticity_token, only: :index

  layout 'stash_engine/application'

  # get search results from the solr index
  def index
    set_cached_latest

    respond_to do |format|
      format.html { store_preferred_view }
      format.js
    end
  end

  private

  def set_cached_latest
    @document_list = JSON.parse(
      Rails.cache.fetch('latest_datasets', expires_in: 10.minutes) do
        response = StashApi::SolrSearchService.new(query: '', filters: '').latest
        response['docs'].to_json
      end
    )
  end
end
