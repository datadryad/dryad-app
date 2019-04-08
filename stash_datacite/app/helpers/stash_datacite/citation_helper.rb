module StashDatacite

  module CitationHelper

    def cite(resource)
      review = StashDatacite::Resource::Review.new(resource)
      make_citation(
        review.authors,
        review.title_str,
        review.resource_type,
        version_string_for(resource, review),
        identifier_string_for(resource, review),
        review.publisher,
        resource.publication_years
      )
    end

    private

    # rubocop:disable Metrics/ParameterLists, Metrics/AbcSize
    def make_citation(authors, title, resource_type, version, identifier, publisher, publication_years)
      citation = []
      citation << h("#{author_citation_format(authors)} (#{pub_year_from(publication_years)})")
      citation << h(title)
      citation << h(version == 'v1' ? '' : version)
      citation << h(publisher.try(:publisher))
      citation << h(resource_type.try(:resource_type_general_friendly))
      id_str = "https://doi.org/#{identifier}"
      citation << "<a href=\"#{id_str}\">#{h(id_str)}</a>"
      citation.reject(&:blank?).join(', ').html_safe
    end
    # rubocop:enable Metrics/ParameterLists, Metrics/AbcSize

    def author_citation_format(authors)
      return '' if authors.blank?
      str_author = authors.map { |c| c.author_full_name unless c.author_full_name =~ /^[ ,]+$/ }.compact
      return '' if str_author.blank?
      return "#{str_author.first} et al." if str_author.length > 4
      str_author.join('; ')
    end

    def pub_year_from(publication_years)
      publication_years.try(:first).try(:publication_year) || Time.now.year
    end

    def identifier_string_for(resource, review)
      return 'DOI' unless resource.identifier
      review.identifier.identifier.to_s
    end

    def version_string_for(resource, review)
      return 'v0' unless resource.stash_version
      "v#{review.version.version}"
    end

    def h(str)
      ERB::Util.html_escape(str)
    end

  end

end
