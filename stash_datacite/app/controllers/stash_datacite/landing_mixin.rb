require 'loofah'

module StashDatacite
  # StashDatacite specific accessors for landing page
  module LandingMixin
    def self.included(landing_controller)
      landing_controller.helper_method :citation
      landing_controller.helper_method :review
      landing_controller.helper_method :schema_org_ds
      landing_controller.helper_method :page_title
    end

    def geolocation_data?
      review.geolocation_data?
    end

    def review
      @review ||= StashDatacite::Resource::Review.new(resource)
    end

    def page_title # TODO: is this used?
      @page_title ||= review.title_str
    end

    def schema_org_ds
      @schema_org_ds ||= schema_org_json_for(resource)
    end

    def pdf_meta
      @pdf_meta ||= StashDatacite::ResourcesController::PdfMetadata.new(resource, id, plain_citation)
    end

    private

    def plain_citation
      citation = make_citation(review, resource)
      ActionController::Base.helpers.strip_tags(citation)
    end

    def make_citation(review, resource)
      citation(
        review.authors,
        review.title_str,
        review.resource_type,
        version_string_for(resource, review),
        identifier_string_for(resource, review),
        review.publisher,
        resource.publication_years
      )
    end

    # rubocop:disable Metrics/ParameterLists, Metrics/AbcSize
    def citation(authors, title, resource_type, version, identifier, publisher, publication_years)
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

    def schema_org_json_for(resource)
      ds_presenter = StashDatacite::ResourcesController::DatasetPresenter.new(resource)
      landing_page_url = stash_url_helpers.show_url(ds_presenter.external_identifier, host: request.host)
      schema_dataset = StashDatacite::Resource::SchemaDataset.new(
        resource: resource,
        citation: plain_citation,
        landing: landing_page_url
      ).generate
      JSON.pretty_generate(schema_dataset).html_safe
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
