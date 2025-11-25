module SearchHelper
  def filter_to_term
    {
      institutions: :org,
      journals: :journalISSN,
      publication_years: :year,
      file_extensions: :fileExt,
      subject_keywords: :subject
    }
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
    return StashEngine::RorOrg.find_by(ror_id: value)&.name if type == :institutions

    value
  end

  def list_filters(type, array)
    is_open = params.key?(filter_to_term[type])

    list = '<div class="search-filter"><h4 class="expand-button">'
    list += "<button id=\"filter_#{type}\" aria-expanded=\"#{is_open}\" aria-controls=\"filter_#{type}_sec\">#{type.to_s.humanize}</button></h4>"
    list += "<ul id=\"filter_#{type}_sec\" class=\"o-list\" #{'hidden' unless is_open} >"

    array.each_slice(2) do |v, i|
      selected = is_open && params[filter_to_term[type]].include?(v)
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

  def display_filters(facets)
    filters = {
      institutions: 'ror_ids_sm',
      journals: 'dryad_related_publication_issn_s',
      publication_years: 'solr_year_i',
      file_extensions: 'dryad_dataset_file_ext_sm',
      subject_keywords: 'dc_subject_sm'
    }
    list = ''
    filters.each do |k, v|
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

end
