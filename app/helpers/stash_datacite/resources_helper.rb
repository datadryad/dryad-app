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
      str_creator = creators.map { |c| c.author_full_name unless c.author_full_name =~ /^[ ,]+$/ }.compact
      return '' if str_creator.blank?
      return "#{str_creator.first} et al." if str_creator.length > 4
      str_creator.join('; ')
    end
  end
end
