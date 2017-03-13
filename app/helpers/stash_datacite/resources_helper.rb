module StashDatacite
  module ResourcesHelper
    def citation(creators, title, resource_type, version, identifier, publisher, publication_years)
      publication_year = publication_years.try(:first).try(:publication_year) || Time.now.year
      title = title.try(:title)
      publisher = publisher.try(:publisher)
      resource_type_general = resource_type.try(:resource_type_general_friendly)
      ["#{creator_citation_format(creators)} (#{publication_year})", h(title),
       (version == 'v1' ? nil : h(version)), h(publisher), h(resource_type_general),
       target_url(identifier)].reject(&:blank?).join(', ').html_safe
    end

    def target_url(identifier)
      if identifier
        "#{link_to("https://doi.org/#{identifier}", "https://doi.org/#{identifier}", target: '_blank')}"\
        '(opens in a new window)'
      else
        'https://doi.org/placeholderDOI'
      end
    end

    def creator_citation_format(creators)
      return '' if creators.blank?
      str_creator = creators.map { |c| c.creator_full_name unless c.creator_full_name =~ /^[ ,]+$/ }.compact
      return '' if str_creator.blank?
      return "#{str_creator.first} et al." if str_creator.length > 4
      str_creator.join('; ')
    end

    def display_orcid_id(creator)
      if StashEngine.app.site == "https://sandbox.orcid.org/"
        link_to("https://sandbox.orcid.org/#{creator.orcid_id}",
                "https://sandbox.orcid.org/#{creator.orcid_id}",
                target: '_blank', class: 'c-orcid__id').html_safe
      else
        link_to("https://orcid.org/#{creator.orcid_id}",
                "https://orcid.org/#{creator.orcid_id}",
                target: '_blank', class: 'c-orcid__id').html_safe
      end
    end
  end
end