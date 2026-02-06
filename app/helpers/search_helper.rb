# rubocop:disable Metrics/ModuleLength
module SearchHelper
  def filter_to_term
    {
      research_organizations: :org,
      journals: :journalISSN,
      publication_years: :year,
      file_extensions: :fileExt,
      subject_keywords: :subject,
      author_affiliations: :affiliation,
      funding_organizations: :funder,
      orcid: :orcid,
      award: :award
    }
  end

  def open?(type)
    params.key?(filter_to_term[type])
  end

  def filter_search(type, value)
    merged = [params[filter_to_term[type]], value].flatten.reject(&:blank?).uniq
    merged = merged.first if merged.one?
    new_search_path(request.parameters.except(:action, :controller).merge(filter_to_term[type] => merged))
  end

  def remove_filter(type, value)
    merged = [params[filter_to_term[type]], value].flatten.reject(&:blank?).uniq
    merged -= [value]
    merged = merged.first if merged.one?
    new_search_path(request.parameters.except(:action, :controller).merge(filter_to_term[type] => merged))
  end

  def filter_display(type, value)
    return StashEngine::Journal.find_by_issn(value)&.title if type == :journals
    return StashEngine::RorOrg.find_by(ror_id: value)&.name if %i[research_organizations author_affiliations funding_organizations].include?(type)

    value
  end

  def list_filters(type, array)
    list = '<div class="search-filter"><h4 class="expand-button">'
    list += "<button id=\"filter_#{type}\" aria-expanded=\"#{open?(type)}\" aria-controls=\"filter_#{type}_sec\">#{type.to_s.humanize}</button></h4>"
    list += "<ul id=\"filter_#{type}_sec\" class=\"o-list\" #{'hidden' unless open?(type)} >"

    array.each_slice(2) do |v, i|
      selected = open?(type) && params[filter_to_term[type]].include?(v)
      list += "<li>#{selected ? filter_display(type, v) : link_to(filter_display(type, v), filter_search(type, v))}"
      list += if selected
                "<a href=\"#{remove_filter(type, v)}\" aria-label=\"Remove\"><i class=\"fas fa-trash-can\"></i></a>"
              else
                "<span class=\"filter-count\">#{i}</span>"
              end
      list += '</li>'
    end

    list += '</ul></div>'
    list.html_safe
  end

  def filter_to_solr
    filters = {
      journals: 'dryad_related_publication_issn_s',
      publication_years: 'solr_year_i',
      file_extensions: 'dryad_dataset_file_ext_sm',
      subject_keywords: 'dc_subject_sm'
    }
    filters.delete(:publication_years) if params.key?('publishedBefore') || params.key?('publishedSince')
    ror_filters = {
      author_affiliations: 'dryad_author_affiliation_id_sm',
      funding_organizations: 'funder_ror_ids_sm',
      research_organizations: 'ror_ids_sm'
    }
    ror_filters.each do |k, v|
      next unless open?(k) || k == :research_organizations

      filters = { k => v }.merge(filters)
      break
    end
    filters
  end

  def display_filters(facets)
    list = ''
    filter_to_solr.each do |k, v|
      next unless facets[v].present?

      list += list_filters(k, facets[v])
    end
    list.html_safe
  end

  def meta_array(arr, c)
    return '' if arr.nil?

    str = "<span class=\"#{c}\">#{c.humanize}: #{arr.join(', ')}.</span>"
    str.html_safe
  end

  def meta_list(result)
    str = ''
    str += "<em>#{result['dryad_related_publication_name_s']}</em>." if result.key?('dryad_related_publication_name_s')
    str += meta_array(result['funding_sm'], 'funding')
    str += meta_array(result['dryad_dataset_file_ext_sm'], 'file_extensions')
    str += meta_array(result['dryad_author_affiliation_name_sm'], 'affiliations')
    str.html_safe
  end

  def result_citation(citation, issn)
    c = JSON.parse(citation)
    str = c['author'].first(3).map { |a| a['family'] }.join(', ')
    str += ', et al' if c['author'].size > 3
    str += '. '
    str += "(#{c.dig('issued', 'date-parts').first.first}) " if c.dig('issued', 'date-parts').present?
    str += " <a href=\"https://doi.org/#{c['DOI']}\" target=\"_blank\" rel=\"noreferrer\">#{c['title']}"
    str += '<i class="fas fa-arrow-up-right-from-square exit-icon" aria-label=" (opens in new window)" role="img"></i></a>. '
    str += "<a href=\"#{new_search_path(journalIssn: issn)}\">" if issn.present?
    str += "<em>#{c['container-title']}</em>"
    str += '</a>' if issn.present?
    str.html_safe
  end

  def get_max(metrics)
    return 10 if metrics.empty?

    number = metrics.max { |a, b| a[:y] <=> b[:y] }[:y].to_i
    divisor = 10**Math.log10(number).floor
    i = number / divisor
    remainder = number % divisor
    return i * divisor if remainder == 0

    (i + 1) * divisor
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

  # rubocop:disable Metrics/AbcSize
  def metrics_chart(doi)
    metrics = Datacite::Metadata.new(doi: doi).metrics
    views = metrics[:views]
    downloads = metrics[:downloads]
    citations = metrics[:citations]
    return { dates: [Date.today.strftime('%Y')], views: [], downloads: [], citations: [] } unless metrics.dig(:views, 0).present?

    range = (Date.parse("#{metrics[:views].first['yearMonth']}-01")..Date.today).map { |d| d.strftime('%Y-%m') }.uniq

    if range.length > 60
      range = range.map { |d| d[0..3] }.uniq
      views = group_metric(views)
      downloads = group_metric(downloads)
    end

    {
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
# rubocop:enable Metrics/ModuleLength, Metrics/AbcSize
