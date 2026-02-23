class SearchController < ApplicationController
  include StashEngine::SharedController
  include StashEngine::SharedSecurityController
  protect_from_forgery except: :metrics_chart

  def search
    respond_to do |format|
      format.html do
        service = StashApi::SolrSearchService.new(query: params[:q], filters: params.except(:q, :action, :controller))
        result = service.search(page: page, per_page: per_page, fields: fields, facet: true)
        if (error = service.error)
          render status: error.status, plain: error.message and return
        end

        @facets = result['facet_counts']
        @results = result['response']
        @profiles = profiles
      end
      format.xml do
        render xml: atom_xml(xml_result), content_type: 'application/atom+xml'
      end
    end
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

  # rubocop:disable Metrics/AbcSize
  def metrics_chart
    metrics = Datacite::Metadata.new(doi: params[:doi]).metrics
    views = metrics[:views]
    downloads = metrics[:downloads]
    citations = metrics[:citations]
    respond_to do |format|
      format.js do
        return @metrics = { dates: [Date.today.strftime('%Y')], views: [], downloads: [], citations: [] } unless metrics.dig(:views, 0).present?

        range = (Date.parse("#{metrics[:views].first['yearMonth']}-01")..Date.today).map { |d| d.strftime('%Y-%m') }.uniq

        if range.length > 36
          range = range.map { |d| d[0..3] }.uniq
          views = group_metric(views)
          downloads = group_metric(downloads)
        end

        @metrics = {
          dates: range.map { |d| label_format(d) },
          views: views.map { |m| { x: label_format(range.reverse.find { |d| d.start_with?(m['yearMonth']) }), y: m['total'] } },
          downloads: downloads.map { |m| { x: label_format(range.reverse.find { |d| d.start_with?(m['yearMonth']) }), y: m['total'] } },
          citations: citations.reject { |m| m['year'] == '0000' }.map do |m|
            { x: label_format(range.reverse.find do |d|
              d.start_with?(m['year'])
            end), y: m['total'] }
          end
        }
      end
    end
  end
  # rubocop:enable Metrics/AbcSize

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

      StashEngine::CounterCitation.citation_metadata(doi: doi, stash_identifier: id)&.metadata
    end
  end

  def page
    @page ||= (params[:page].respond_to?(:to_i) && params[:page].to_i.positive? ? params[:page].to_i : 1)
  end

  def per_page
    @page_size = 10 if params[:page_size].blank? || params[:page_size].to_i == 0
    @page_size ||= params[:page_size].to_i
  end

  def xml_result
    filters = URI.encode_www_form(params.except(:q, :action, :controller, :id, :page_size, :format, :utf8).to_unsafe_hash.sort.to_h)
    Rails.cache.fetch("xml_search/#{filters}", expires_in: 12.hours) do
      service = StashApi::SolrSearchService.new(query: params[:q], filters: params.except(:q, :action, :controller, :id).merge(sort: 'date desc'))
      service.search(page: page, per_page: 10, fields: fields, facet: true, wt: :xml)
      if (error = service.error)
        render status: error.status, plain: error.message and return
      end
    end
  end

  def atom_xml(result)
    ps = StashEngine::PublicSearch.find_by(id: params[:id])
    url = new_search_url(request.parameters.except(:action, :controller, :page, :page_size, :format)).gsub('/search', '/search.xml')
    xml = Nokogiri::XML::Document.parse(result)
    xsl = Nokogiri::XSLT.parse(File.read(File.expand_path('../views/search/atom.xsl', File.dirname(__FILE__))))
    xsl_params = Nokogiri::XSLT.quote_params(
      { 'url' => url.to_s,
        'title' => ps&.title || 'Dryad search results',
        'desc' => ps&.description,
        'page' => page }
    )
    xsl.transform(xml, xsl_params).to_xml
  end

  def label_format(d)
    c = d.split('-')
    return Date.new(c.first.to_i, c.last.to_i, 1).strftime('%b %Y') if d.length > 4

    d
  end

  def group_metric(metric)
    h = metric.group_by { |m| m['yearMonth'][0..3] }
    h.map { |k, v| { 'yearMonth' => k, 'total' => v.sum { |m| m['total'] } } }
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
