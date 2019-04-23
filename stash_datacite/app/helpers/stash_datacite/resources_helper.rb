module StashDatacite
  module ResourcesHelper
    def citation(authors, title, resource_type, version, identifier, publisher, publication_year) # rubocop:disable Metrics/ParameterLists
      [
        "#{author_citation_format(authors)} (#{publication_year})",
        escape_title(title),
        escape_version(version),
        escape_publisher(publisher),
        escape_resource_type(resource_type),
        doi_link(identifier)
      ].reject(&:blank?).join(', ').html_safe
    end

    def doi_link(identifier)
      return 'https://doi.org/placeholderDOI' unless identifeir
      target_url = "https://doi.org/#{identifier}"
      doi_link = link_to(target_url, target_url, target: '_blank')
      "#{doi_link} (opens in a new window)"
    end

    def author_citation_format(authors)
      return '' if authors.blank?
      str_author = authors.map { |c| c.author_full_name unless c.author_full_name =~ /^[ ,]+$/ }.compact
      return '' if str_author.blank?
      return "#{str_author.first} et al." if str_author.length > 4
      str_author.join('; ')
    end

    private

    def pub_year_from(publication_years)
      return publication_years.year if publication_years.is_a?(Date)
      publication_years.try(:first).try(:publication_year) || Time.now.year
    end

    def escape_title(title)
      html_escape(title)
    end

    def escape_version(version)
      (version == 'v1' ? nil : html_escape(version))
    end

    def escape_publisher(publisher)
      html_escape(publisher.try(:publisher))
    end

    def escape_resource_type(resource_type)
      html_escape(resource_type.try(:resource_type_general_friendly))
    end

  end
end
