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
    @profiles = profiles
  end

  def advanced
    service = StashApi::SolrSearchService.new(query: '', filters: {})
    search = service.search(page: page, per_page: per_page, fields: 'dc_identifier_s', facet: true)
    @facets = search['facet_counts']
  end

  def author_profile
    @author = author
    service = StashApi::SolrSearchService.new(query: '', filters: params.except(:q, :action, :controller))
    search = service.search(page: page, per_page: per_page, fields: "#{fields} dryad_related_publication_issn_s", facet: false)
    @results = search['response']
    @articles = articles
  end

  # Endpoint called from LinkOut buttons on Pubmed site but could be used to locate a Dataset
  # based on manuscript number or pubmed id
  # GET discover?query=doi/pmid/manuscript
  def discover
    query = params[:query].to_s.gsub('"', '')
    query = query.gsub('doi:', '') if query.start_with?('doi:')

    identifiers = find_related(StashApi::SolrSearchService.new(query: nil, filters: { relatedId: query }).search)

    redirect_discover_to_landing(identifiers, query)
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

  def profiles
    d = []
    d << author if params['orcid'].present?
    [params['affiliation'], params['org'], params['funder']].flatten.reject(&:blank?).each do |o|
      d << StashEngine::RorOrg.find_by(ror_id: o)
    end
    d.reject(&:blank?)
  end

  def author
    StashEngine::Author.joins(:resource).where(resource: { solr_indexed: true }, author_orcid: params[:orcid]).last
  end

  def articles
    return unless @results['docs'].present?

    @results['docs'].map do |d|
      id = StashEngine::Identifier.find_by(identifier: d['dc_identifier_s'].gsub('doi:', ''))
      doi = id&.publication_article_doi
      next nil unless doi.present?

      StashEngine::CounterCitation.citation_metadata(doi: doi, stash_identifier: id).metadata
    end
  end

  def page
    @page ||= (params[:page].respond_to?(:to_i) && params[:page].to_i.positive? ? params[:page].to_i : 1)
  end

  def per_page
    @page_size = 10 if params[:page_size].blank? || params[:page_size].to_i == 0
    @page_size ||= params[:page_size].to_i
  end

  def find_related(related)
    return [] unless related.is_a?(Hash)

    dois = related.dig('response', 'docs')
    ids = dois.map { |a| a['dc_identifier_s'].gsub('doi:', '') } if dois&.any?
    StashEngine::Identifier.where(identifier: ids)
  end

  def redirect_discover_to_landing(identifiers, query)
    if identifiers.length > 1
      # Found multiple datasets for the publication, so redirect to search
      redirect_to new_search_path(q: '', relatedId: query.to_s) and return
    elsif identifiers.length == 1
      # Found one match, redirect to the landing page
      redirect_to stash_url_helpers.show_path(identifiers.first&.to_s) and return
    else
      # Nothing was found, check if we were sent a Dryad DOI
      identifier = StashEngine::Identifier.find_by(identifier: query.to_s)
      redirect_to stash_url_helpers.show_path(identifier.to_s) and return if identifier.present?

      # Nothing was found, redirect to search
      redirect_to new_search_path(q: query.to_s) if identifier.blank?
    end
  end
end
