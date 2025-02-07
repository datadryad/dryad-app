# require 'blacklight/catalog'

# rubocop:disable Security/YAMLLoad
settigs = YAML.load(File.open(File.join('config', 'settings.yml')), symbolize_names: true, aliases: true)
Settings = JSON.parse(settigs.to_json, object_class: OpenStruct)
# rubocop:enable Security/YAMLLoad

class CatalogController < ApplicationController

  # these were in application controller for sample app
  include Blacklight::Controller
  # this was in the catalog controller of sample app
  include Blacklight::Catalog

  helper StashEngine::ApplicationHelper
  include StashEngine::SharedController

  # layout 'blacklight_layout'
  # layout 'stash_engine/application'
  layout :determine_layout if respond_to? :layout

  configure_blacklight do |config|
    config.bootstrap_version = 5
    config.track_search_session.storage = false

    ## Default parameters to send to solr for all search-like requests. See also SearchBuilder#processed_parameters
    config.default_solr_params = {
      :start => 0,
      :rows => 10,
      'q.alt' => '*:*'
    }

    # items to show per page, each number in the array represent another option to choose from.
    # config.per_page = [10,20,50,100]

    # solr field configuration for search results/index views
    config.index.title_field = Settings.FIELDS.TITLE
    config.index.display_type_field = 'format'

    # The presenter is the view-model class for the page
    config.index.document_presenter_class = Blacklight::IndexPresenter

    # Some components can be configured
    # config.index.document_component = Blacklight::SearchResultComponent
    # config.index.constraints_component = Blacklight::ConstraintsComponent
    config.index.search_bar_component = Blacklight::SearchBarComponent
    # config.index.search_header_component = Blacklight::SearchHeaderComponent
    config.index.document_actions.delete(:bookmark)

    # config.add_results_document_tool(:bookmark, component: Blacklight::Document::BookmarkComponent, if: :render_bookmarks_control?)

    config.add_results_collection_tool(:sort_widget)
    config.add_results_collection_tool(:per_page_widget)
    config.add_results_collection_tool(:view_type_group)

    # config.add_show_tools_partial(:bookmark, component: Blacklight::Document::BookmarkComponent, if: :render_bookmarks_control?)
    config.add_show_tools_partial(:email, callback: :email_action, validator: :validate_email_params)
    config.add_show_tools_partial(:sms, if: :render_sms_action?, callback: :sms_action, validator: :validate_sms_params)
    config.add_show_tools_partial(:citation)

    # config.add_nav_action(:bookmark, partial: 'blacklight/nav/bookmark', if: :render_bookmarks_control?)
    config.add_nav_action(:search_history, partial: 'blacklight/nav/search_history')

    # The presenter is a view-model class for the page
    config.index.document_presenter_class = Blacklight::IndexPresenter

    # These components can be configured
    # config.show.document_component = MyApp::DocumentComponent
    # config.show.sidebar_component = Blacklight::HeaderComponent

    config.add_facet_field Settings.FIELDS.SUBJECT, label: 'Subject keyword', limit: 8
    config.add_facet_field Settings.FIELDS.SPATIAL_COVERAGE, label: 'Geographical Location', limit: 8
    config.add_facet_field Settings.FIELDS.PART_OF, label: 'Collection', limit: 8
    config.add_facet_field Settings.FIELDS.RELATED_PUBLICATION_NAME, label: 'Journal', limit: 8
    config.add_facet_field Settings.FIELDS.AUTHOR_AFFILIATION_NAME, label: 'Institution', limit: 8
    config.add_facet_field Settings.FIELDS.DATASET_FILE_EXT, label: 'File Extension', limit: 8
    config.add_facet_field Settings.FIELDS.FUNDER, label: 'Funder', limit: 8

    # config.add_facet_field Settings.FIELDS.RIGHTS, label: 'Access', limit: 8, partial: "icon_facet"
    # config.add_facet_field Settings.FIELDS.GEOM_TYPE, label: 'Data type', limit: 8, partial: "icon_facet"

    config.add_facet_fields_to_solr_request!

    # solr fields to be displayed in the index (search results) view
    #   The ordering of the field names is the order of the display
    config.add_index_field Settings.FIELDS.CREATOR
    config.add_index_field Settings.FIELDS.DESCRIPTION # , helper_method: :snippit

    config.add_show_field Settings.FIELDS.CREATOR, label: 'Author(s)', itemprop: 'author'
    config.add_show_field Settings.FIELDS.DESCRIPTION, label: 'Description',
                                                       itemprop: 'description', helper_method: :render_value_as_truncate_abstract
    # config.add_show_field Settings.FIELDS.PUBLISHER, label: 'Institution', itemprop: 'publisher'
    config.add_show_field Settings.FIELDS.PART_OF, label: 'Collection', itemprop: 'isPartOf'
    config.add_show_field Settings.FIELDS.SPATIAL_COVERAGE, label: 'Geographical location(s)', itemprop: 'spatial', link_to_search: true
    config.add_show_field Settings.FIELDS.SUBJECT, label: 'Subject keyword(s)', itemprop: 'keywords', link_to_search: true
    config.add_show_field Settings.FIELDS.TEMPORAL, label: 'Year', itemprop: 'temporal'
    config.add_show_field Settings.FIELDS.PROVENANCE, label: 'Held by', link_to_search: true
    config.add_show_field Settings.FIELDS.RELATED_PUBLICATION_NAME, label: 'Journal', itemprop: 'related_publication_name'
    config.add_show_field Settings.FIELDS.AUTHOR_AFFILIATION_NAME, label: 'Institution', itemprop: 'author_affiliation_name'

    config.add_sort_field 'score desc, dc_title_sort asc', label: 'relevance'
    config.add_sort_field "#{Settings.FIELDS.YEAR} desc, dc_title_sort asc", label: 'year'
    config.add_sort_field "#{Settings.FIELDS.PUBLISHER} asc, dc_title_sort asc", label: 'institution'
    config.add_sort_field 'dc_title_sort asc', label: 'title'

    # If there are more than this many search results, no spelling ("did you
    # mean") suggestion is offered.
    config.spell_max = 5

    # Configuration for autocomplete suggester
    config.autocomplete_enabled = true
    config.autocomplete_path = 'suggest'
  end

  ##
  # Overrides default Blacklight method to return true for an empty q value
  # @return [Boolean]
  #
  # this has the effect of making a blank query (with a q=) show the results
  # list rather than the welcome page.
  # rubocop:disable Naming/PredicateName
  def has_search_parameters?
    !params[:q].nil? || super
  end
  # rubocop:enable Naming/PredicateName

  # Endpoint called from LinkOut buttons on Pubmed site but could be used to locate a Dataset
  # based on the InternalDatum types defined below
  # GET discover?query=[:internal_datum_value]
  def discover
    internal_datum_types = %w[pubmedID manuscriptNumber]
    where_clause = 'stash_engine_internal_data.data_type IN (?) AND stash_engine_internal_data.value = ?'
    internal_data = StashEngine::Identifier
      .publicly_viewable.distinct.joins(:internal_data)
      .where(where_clause, internal_datum_types, params[:query])

    related_dois = StashApi::SolrSearchService.new(
      query: nil,
      filters: {
        'relatedWorkIdentifier' => "*#{params[:query]}",
        'relatedWorkRelationship' => 'primary_article'
      }
    ).search['docs']
    related_dois = related_dois.map { |a| a['dc_identifier_s'].gsub('doi:', '') } if related_dois.any?
    related_ids = StashEngine::Identifier.where(identifier: related_dois)

    identifiers = internal_data + related_ids

    redirect_discover_to_landing(identifiers, params[:query])
  end

  private

  def redirect_discover_to_landing(identifiers, query)
    if identifiers.length > 1
      # Found multiple datasets for the publication so do a Blacklight search for their DOIs
      redirect_to search_catalog_path(q: query.to_s)
    elsif identifiers.length == 1
      # Found one match so just send them to the landing page
      redirect_to stash_url_helpers.show_path(identifiers.first&.to_s)
    else
      # Nothing was found so see if we were sent a Dryad DOI
      identifier = StashEngine::Identifier.find_by(identifier: query.to_s)
      redirect_to stash_url_helpers.show_path(identifier.to_s) if identifier.present?

      # Nothing was found so send the user to the Blacklight search page with the original query
      redirect_to search_catalog_path(q: query.to_s) if identifier.blank?
    end
  end

end
