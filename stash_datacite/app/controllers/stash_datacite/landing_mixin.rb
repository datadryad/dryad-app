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
      ds_presenter = StashDatacite::ResourcesController::DatasetPresenter.new(@resource)
      @data = check_required_fields(@resource)
      @review = StashDatacite::Resource::Review.new(@resource)

      @schema_org_ds = StashDatacite::Resource::SchemaDataset.new(resource: @resource, citation: plain_citation,
                                                                  landing: stash_url_helpers.show_url(ds_presenter.external_identifier, host: request.host)).generate
      @schema_org_ds = JSON.pretty_generate(@schema_org_ds).html_safe

      if @review.no_geolocation_data == true
        @resource.has_geolocation = false
        @resource.save!
      end
    end

    private

    def check_required_fields(resource)
      @completions = Resource::Completions.new(resource)
      # required fields are Title, Institution, Data type, Data author(s), Abstract
      unless @completions.required_completed == @completions.required_total
        @data = []
        @data << 'Title' unless @completions.title
        @data << 'Resource Type' unless @completions.data_type
        @data << 'Abstract' unless @completions.abstract
        @data << 'Author(s) Name' unless @completions.author_name
        @data << 'Author Email' unless @completions.author_email
        @data << 'Author Affiliation' unless @completions.author_affiliation
        return @data.join(', ').split(/\W+/)
      end
    end

    def plain_citation
      citation(
          @review.authors,
          @review.title,
          @review.resource_type,
          @resource.stash_version.nil? ? 'v0' : "v#{@review.version.version }",
          @resource.identifier.nil? ? 'DOI' : "#{@review.identifier.identifier }",
          "#{@review.publisher}",
          @resource.publication_years)
    end

    def citation(authors, title, resource_type, version, identifier, publisher, publication_years)
      publication_year = publication_years.try(:first).try(:publication_year) || Time.now.year
      title = title.try(:title)
      publisher = publisher.try(:publisher)
      resource_type_general = resource_type.try(:resource_type_general_friendly)
      ["#{author_citation_format(authors)} (#{publication_year})", title,
       (version == 'v1' ? nil : version), publisher, resource_type_general,
       "https://doi.org/#{identifier}"].reject(&:blank?).join(', ')
    end

    def author_citation_format(authors)
      return '' if authors.blank?
      str_author = authors.map { |c| c.author_full_name unless c.author_full_name =~ /^[ ,]+$/ }.compact
      return '' if str_author.blank?
      return "#{str_author.first} et al." if str_author.length > 4
      str_author.join('; ')
    end

  end
end
