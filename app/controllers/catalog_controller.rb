require 'blacklight/catalog'

class CatalogController < ApplicationController

  # these were in application controller for sample app
  include Blacklight::Controller
  # this was in the catalog controller of sample app
  include Blacklight::Catalog

  helper StashEngine::ApplicationHelper
  include StashEngine::SharedController

  # layout 'geoblacklight_layout'
  # layout 'stash_engine/application'
  layout :determine_layout if respond_to? :layout

  configure_blacklight do |config|
    ## Default parameters to send to solr for all search-like requests. See also SolrHelper#solr_search_params
    config.default_solr_params = {
      :start => 0,
      :rows => 10,
      'q.alt' => '*:*'
    }

    ## Default parameters to send on single-document requests to Solr. These settings are the Blackligt defaults (see SolrHelper#solr_doc_params) or
    ## parameters included in the Blacklight-jetty document requestHandler.
    #
    config.default_document_solr_params = {
      qt: 'document',
      q: '{!raw f=layer_slug_s v=$id}'
    }

    # solr field configuration for search results/index views
    # config.index.show_link = 'title_display'
    # config.index.record_display_type = 'format'

    config.index.title_field = Settings.FIELDS.TITLE

    # solr field configuration for document/show views

    config.show.display_type_field = 'format'

    ##
    # Configure the index document presenter.
    config.index.document_presenter_class = Geoblacklight::DocumentPresenter

    # solr fields that will be treated as facets by the blacklight application
    #   The ordering of the field names is the order of the display
    #
    # Setting a limit will trigger Blacklight's 'more' facet values link.
    # * If left unset, then all facet values returned by solr will be displayed.
    # * If set to an integer, then "f.somefield.facet.limit" will be added to
    # solr request, with actual solr request being +1 your configured limit --
    # you configure the number of items you actually want _displayed_ in a page.
    # * If set to 'true', then no additional parameters will be sent to solr,
    # but any 'sniffed' request limit parameters will be used for paging, with
    # paging at requested limit -1. Can sniff from facet.limit or
    # f.specific_field.facet.limit solr request params. This 'true' config
    # can be used if you set limits in :default_solr_params, or as defaults
    # on the solr side in the request handler itself. Request handler defaults
    # sniffing requires solr requests to be made with "echoParams=all", for
    # app code to actually have it echo'd back to see it.
    #
    # :show may be set to false if you don't want the facet to be drawn in the
    # facet bar
    # config.add_facet_field 'format', :label => 'Format'
    # config.add_facet_field 'pub_date', :label => 'Publication Year', :single => true
    # config.add_facet_field 'subject_topic_facet', :label => 'Topic', :limit => 20
    # config.add_facet_field 'language_facet', :label => 'Language', :limit => true
    # config.add_facet_field 'lc_1letter_facet', :label => 'Call Number'
    # config.add_facet_field 'subject_geo_facet', :label => 'Region'
    # config.add_facet_field 'solr_bbox', :fq => "solr_bbox:IsWithin(-88,26,-79,36)", :label => 'Spatial'

    # config.add_facet_field 'example_pivot_field', :label => 'Pivot Field', :pivot => ['format', 'language_facet']

    # config.add_facet_field 'example_query_facet_field', :label => 'Publish Date', :query => {
    #    :years_5 => { :label => 'within 5 Years', :fq => "pub_date:[#{Time.now.year - 5 } TO *]" },
    #    :years_10 => { :label => 'within 10 Years', :fq => "pub_date:[#{Time.now.year - 10 } TO *]" },
    #    :years_25 => { :label => 'within 25 Years', :fq => "pub_date:[#{Time.now.year - 25 } TO *]" }
    # }

    # config.add_facet_field Settings.FIELDS.PROVENANCE, label: 'Institution', limit: 8, partial: "icon_facet"
    # config.add_facet_field Settings.FIELDS.CREATOR, :label => 'Author', :limit => 8
    # config.add_facet_field 'dc_type_s', label: 'Type', limit: 8
    # config.add_facet_field Settings.FIELDS.PUBLISHER, label: 'Institution', limit: 8
    config.add_facet_field Settings.FIELDS.SUBJECT, label: 'Subject keyword', limit: 8
    config.add_facet_field Settings.FIELDS.SPATIAL_COVERAGE, label: 'Geographical Location', limit: 8
    config.add_facet_field Settings.FIELDS.PART_OF, label: 'Collection', limit: 8
    config.add_facet_field Settings.FIELDS.RELATED_PUBLICATION_NAME, label: 'Journal', limit: 8
    config.add_facet_field Settings.FIELDS.AUTHOR_AFFILIATION_NAME, label: 'Institution', limit: 8
    config.add_facet_field Settings.FIELDS.DATASET_FILE_EXT, label: 'File Extension', limit: 8
    config.add_facet_field Settings.FIELDS.FUNDER, label: 'Funder', limit: 8

    # config.add_facet_field Settings.FIELDS.RIGHTS, label: 'Access', limit: 8, partial: "icon_facet"
    # config.add_facet_field Settings.FIELDS.GEOM_TYPE, label: 'Data type', limit: 8, partial: "icon_facet"

    # Have BL send all facet field names to Solr, which has been the default
    # previously. Simply remove these lines if you'd rather use Solr request
    # handler defaults, or have no facets.
    config.add_facet_fields_to_solr_request!

    # solr fields to be displayed in the index (search results) view
    #   The ordering of the field names is the order of the display
    # config.add_index_field 'title_display', :label => 'Title:'
    # config.add_index_field 'title_vern_display', :label => 'Title:'
    # config.add_index_field 'author_display', :label => 'Author:'
    # config.add_index_field 'author_vern_display', :label => 'Author:'
    # config.add_index_field 'format', :label => 'Format:'
    # config.add_index_field 'language_facet', :label => 'Language:'
    # config.add_index_field 'published_display', :label => 'Published:'
    # config.add_index_field 'published_vern_display', :label => 'Published:'
    # config.add_index_field 'lc_callnum_display', :label => 'Call number:'

    # config.add_index_field 'dc_title_t', :label => 'Display Name:'
    # config.add_index_field Settings.FIELDS.PROVENANCE, :label => 'Institution:'
    # config.add_index_field Settings.FIELDS.RIGHTS, :label => 'Access:'
    # # config.add_index_field 'Area', :label => 'Area:'
    # config.add_index_field Settings.FIELDS.SUBJECT, :label => 'Keywords:'
    config.add_index_field Settings.FIELDS.YEAR
    config.add_index_field Settings.FIELDS.CREATOR
    config.add_index_field Settings.FIELDS.DESCRIPTION, helper_method: :snippit
    # config.add_index_field Settings.FIELDS.PUBLISHER
    config.add_index_field Settings.FIELDS.RELATED_PUBLICATION_NAME
    config.add_index_field Settings.FIELDS.AUTHOR_AFFILIATION_NAME
    config.add_index_field Settings.FIELDS.DATASET_FILE_EXT
    config.add_index_field Settings.FIELDS.FUNDER

    # solr fields to be displayed in the show (single result) view
    #  The ordering of the field names is the order of the display
    #
    # item_prop: [String] property given to span with Schema.org item property
    # link_to_search: [Boolean] that can be passed to link to a facet search
    # helper_method: [Symbol] method that can be used to render the value
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

    # "fielded" search configuration. Used by pulldown among other places.
    # For supported keys in hash, see rdoc for Blacklight::SearchFields
    #
    # Search fields will inherit the :qt solr request handler from
    # config[:default_solr_parameters], OR can specify a different one
    # with a :qt key/value. Below examples inherit, except for subject
    # that specifies the same :qt as default for our own internal
    # testing purposes.
    #
    # The :key is what will be used to identify this BL search field internally,
    # as well as in URLs -- so changing it after deployment may break bookmarked
    # urls.  A display label will be automatically calculated from the :key,
    # or can be specified manually to be different.

    # This one uses all the defaults set by the solr request handler. Which
    # solr request handler? The one set in config[:default_solr_parameters][:qt],
    # since we aren't specifying it otherwise.

    # config.add_search_field 'text', :label => 'All Fields'
    # config.add_search_field 'dc_title_ti', :label => 'Title'
    # config.add_search_field 'dc_description_ti', :label => 'Description'

    # Now we see how to over-ride Solr request handler defaults, in this
    # case for a BL "search field", which is really a dismax aggregate
    # of Solr search fields.

    # config.add_search_field('title') do |field|
    #   # solr_parameters hash are sent to Solr as ordinary url query params.
    #   field.solr_parameters = { :'spellcheck.dictionary' => 'title' }

    #   # :solr_local_parameters will be sent using Solr LocalParams
    #   # syntax, as eg {! qf=$title_qf }. This is neccesary to use
    #   # Solr parameter de-referencing like $title_qf.
    #   # See: http://wiki.apache.org/solr/LocalParams
    #   field.solr_local_parameters = {
    #     :qf => '$title_qf',
    #     :pf => '$title_pf'
    #   }
    # end

    # config.add_search_field('author') do |field|
    #   field.solr_parameters = { :'spellcheck.dictionary' => 'author' }
    #   field.solr_local_parameters = {
    #     :qf => '$author_qf',
    #     :pf => '$author_pf'
    #   }
    # end

    # # Specifying a :qt only to show it's possible, and so our internal automated
    # # tests can test it. In this case it's the same as
    # # config[:default_solr_parameters][:qt], so isn't actually neccesary.
    # config.add_search_field('subject') do |field|
    #   field.solr_parameters = { :'spellcheck.dictionary' => 'subject' }
    #   field.qt = 'search'
    #   field.solr_local_parameters = {
    #     :qf => '$subject_qf',
    #     :pf => '$subject_pf'
    #   }
    # end

    #  config.add_search_field('Institution') do |field|
    #   field.solr_parameters = { :'spellcheck.dictionary' => 'Institution' }
    #   field.solr_local_parameters = {
    #     :qf => '$Institution_qf',
    #     :pf => '$Institution_pf'
    #   }
    # end

    # "sort results by" select (pulldown)
    # label in pulldown is followed by the name of the SOLR field to sort by and
    # whether the sort is ascending or descending (it must be asc or desc
    # except in the relevancy case).
    config.add_sort_field 'score desc, dc_title_sort asc', label: 'relevance'
    config.add_sort_field "#{Settings.FIELDS.YEAR} desc, dc_title_sort asc", label: 'year'
    config.add_sort_field "#{Settings.FIELDS.PUBLISHER} asc, dc_title_sort asc", label: 'institution'
    config.add_sort_field 'dc_title_sort asc', label: 'title'

    # If there are more than this many search results, no spelling ("did you
    # mean") suggestion is offered.
    config.spell_max = 5

    # Custom tools for GeoBlacklight
    config.add_show_tools_partial :web_services,
                                  if: proc { |_context, _config, options|
                                        options[:document] &&
                                             (Settings.WEBSERVICES_SHOWN & options[:document].references.refs.map(&:type).map(&:to_s)).any?
                                      }
    config.add_show_tools_partial :metadata,
                                  if: proc { |_context, _config, options|
                                        options[:document] &&
                                             (Settings.METADATA_SHOWN & options[:document].references.refs.map(&:type).map(&:to_s)).any?
                                      }
    config.add_show_tools_partial :exports, partial: 'exports', if: proc { |_context, _config, options| options[:document] }
    config.add_show_tools_partial :data_dictionary, partial: 'data_dictionary', if: proc { |_context, _config, options| options[:document] }
    config.add_show_tools_partial :downloads, partial: 'downloads', if: proc { |_context, _config, options| options[:document] }

    # Configure basemap provider for GeoBlacklight maps (uses https only basemap
    # providers with open licenses)
    # Valid basemaps include:
    # 'positron' http://cartodb.com/basemaps/
    # 'darkMatter' http://cartodb.com/basemaps/
    config.basemap_provider = 'positron'

    # Configuration for autocomplete suggestor
    # config.autocomplete_enabled = true
    # config.autocomplete_path = 'suggest'
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
  # GET stash/discover?query=[:internal_datum_value]
  def discover
    internal_datum_types = %w[pubmedID publicationDOI manuscriptNumber]
    where_clause = 'stash_engine_internal_data.data_type IN (?) AND stash_engine_internal_data.value = ?'
    identifiers = StashEngine::Identifier
      .publicly_viewable.joins(:internal_data)
      .where(where_clause, internal_datum_types, params[:query])

    redirect_discover_to_landing(identifiers, params[:query])
  end

  private

  def redirect_discover_to_landing(identifiers, query)
    if identifiers.length > 1
      # Found multiple datasets for the publication so do a Blacklight search for their DOIs
      redirect_to search_path(q: query.to_s)
    elsif identifiers.length == 1
      # Found one match so just send them to the landing page
      redirect_to stash_url_helpers.show_path(identifiers.first&.to_s)
    else
      # Nothing was found so see if we were sent a Dryad DOI
      identifier = StashEngine::Identifier.find_by(identifier: query.to_s)
      redirect_to stash_url_helpers.show_path(identifier.to_s) if identifier.present?

      # Nothing was found so send the user to the Blacklight search page with the original query
      redirect_to search_path(q: query.to_s) if identifier.blank?
    end
  end

end
