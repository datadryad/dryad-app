class SearchController < ApplicationController
  include StashEngine::SharedController
  include StashEngine::SharedSecurityController

  def search
    service = StashApi::SolrSearchService.new(query: params[:q], filters: params.except(:q, :action, :controller))
    search = service.search(page: page, per_page: per_page, fields: fields, facet: true)
    if (error = service.error)
      render status: error.status, plain: error.message and return
    end

    @facets = search['facet_counts']
    @results = search['response']
  end

  private

  def fields
    f = 'dc_identifier_s dc_title_s dc_creator_sm dc_description_s dc_subject_sm dct_issued_dt'
    f += ' funding_sm' if params.key?(:funder) || params.key?(:award)
    f += ' dryad_dataset_file_ext_sm' if params.key?(:fileExt)
    f += ' dryad_author_affiliation_name_sm' if params.key?(:affiliation)
    f += ' dryad_related_publication_name_s' if params.key?(:journalISSN)
    f
  end

  def page
    @page ||= (params[:page].respond_to?(:to_i) && params[:page].to_i.positive? ? params[:page].to_i : 1)
  end

  def per_page
    @page_size = 10 if params[:page_size].blank? || params[:page_size].to_i == 0
    @page_size ||= params[:page_size].to_i
  end
end
