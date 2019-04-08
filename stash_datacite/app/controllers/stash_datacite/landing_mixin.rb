require 'loofah'

module StashDatacite
  # StashDatacite specific accessors for landing page
  module LandingMixin

    include CitationHelper

    def self.included(landing_controller)
      landing_controller.helper_method :citation
      landing_controller.helper_method :review
      landing_controller.helper_method :schema_org_ds
      landing_controller.helper_method :page_title
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

    private

    def citation(resource)
      cite(resource) # defer to the CitationHelper for building out the citation text
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

  end
end
