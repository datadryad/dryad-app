module StashDatacite
  module LandingMixin
    def self.included(c)
      c.helper_method :citation
    end

    # this method doesn't have a view but is to set up variables needed for page rendering of the dashboard/review
    # it will be mixed into the appropriate controller class since we need it to work in the context where it is mixed
    # in to set variables for the view.
    # @resource, @data, @review, @schema_org_ds
    def setup_show_variables(resource_id)
      @resource = StashDatacite.resource_class.find(resource_id)
      @review = StashDatacite::Resource::Review.new(@resource)
      @resource.has_geolocation = @review.has_geolocation_data
      @resource.save!
      @schema_org_ds = schema_org_json_for(@resource)
    end

    private

    def plain_citation
      citation(
        @review.authors,
        @review.title,
        @review.resource_type,
        version_string_for(@resource, @review),
        identifier_string_for(@resource, @review),
        @review.publisher.to_s,
        @resource.publication_years
      )
    end

    def citation(authors, title, resource_type, version, identifier, publisher, publication_years) # rubocop:disable Metrics/ParameterLists
      citation = []
      citation << "#{author_citation_format(authors)} (#{pub_year_from(publication_years)})"
      citation << title.try(:title)
      citation << (version == 'v1' ? nil : version)
      citation << publisher.try(:publisher)
      citation << resource_type.try(:resource_type_general_friendly)
      citation << "https://doi.org/#{identifier}"
      citation.reject(&:blank?).join(', ')
    end

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

  end
end
