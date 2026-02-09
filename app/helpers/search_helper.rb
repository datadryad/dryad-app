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

  def result_citation(c, issn)
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
end
# rubocop:enable Metrics/ModuleLength
