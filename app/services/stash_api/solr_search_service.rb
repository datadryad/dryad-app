module StashApi
  class SolrSearchService
    attr_reader :query, :filters
    attr_accessor :error

    def initialize(query:, filters:)
      @query   = parse_query(query)
      @filters = filters
      @error   = nil

      @solr = RSolr.connect(url: APP_CONFIG.solr_url)
    end

    def search(page: 1, per_page: DEFAULT_PAGE_SIZE, fields: 'dc_identifier_s', facet: false)
      params = { q: @query.to_s, fq: filter_query, fl: fields, facet: facet }
      params[:sort] = sort_query if filters.key?('sort')
      @solr.paginate(page, per_page, 'select', params: params)
    rescue RSolr::Error::Http
      @error = OpenStruct.new(status: 400, message: 'Unable to parse query request.')
      []
    end

    def latest
      params = { sort: 'dct_issued_dt desc', rows: 5, fl: 'dc_identifier_s dc_title_s dc_creator_sm dc_description_s' }
      search = @solr.paginate(1, 5, 'select', params: params)
      search['response']
    end

    private

    def parse_query(q)
      # do some light sanitization
      # passing `system(_any_string_)` or `exec(_any_string_)` will return a 403 from solr
      # escaping these as `system\(_any_string_\)` will perform the query as expected
      q&.gsub(/.*\(.*?\).*/) { |match| match.gsub('(', '\(').gsub(')', '\)') }
    end

    def sort_query
      filters['sort'].sub('date', 'dct_issued_dt')
    end

    def solr_exact_map
      {
        affiliation: 'dryad_author_affiliation_id_sm',
        license: 'dc_rights_s',
        fileExt: 'dryad_dataset_file_ext_sm',
        journalISSN: 'dryad_related_publication_issn_s',
        funder: 'funder_ror_ids_sm',
        award: 'funder_awd_ids_sm',
        facility: 'sponsor_ror_ids_sm',
        org: 'ror_ids_sm',
        year: 'solr_year_i'
      }
    end

    def solr_text_map
      {
        doi: 'dc_identifier_ti',
        subject: 'dc_subject_tmi',
        author: 'dc_creator_tmi',
        orcid: 'author_orcids_tmi',
        affiliationName: 'dryad_author_affiliation_name_tmi',
        relatedId: 'dryad_related_publication_id_tmi',
        journal: 'dryad_related_publication_name_ti',
        funderName: 'dcs_funder_tmi'
      }
    end

    # Builds an array of the various filter settings requested
    def filter_query
      @fq_array = []

      filters.each do |k, v|
        next unless v.present?

        add_exact_filter(solr_exact_map[k.to_sym], v) if solr_exact_map.key?(k.to_sym)
        add_text_filter(solr_text_map[k.to_sym], v) if solr_text_map.key?(k.to_sym)
      end

      if filters['tenant'] && StashEngine::Tenant.exists?(filters['tenant'])
        tenant = StashEngine::Tenant.find(filters['tenant'])
        ror_array = tenant.ror_ids.map do |r|
          # map the id into the format
          "ror_ids_sm:\"#{r}\" "
        end
        @fq_array << ror_array.join(' OR ')
      end

      add_related_work_filter(filters['relatedWorkIdentifier'], filters['relatedWorkRelationship'])

      range_filters

      @fq_array
    end

    def range_filters
      if filters['modifiedBefore'] || filters['modifiedSince']
        add_range_filter('updated_at_dt', filters['modifiedSince'] || '*',
                         filters['modifiedBefore'] || 'NOW')
      end
      if filters['publishedSince'] || filters['publishedBefore']
        add_range_filter('dct_issued_dt', filters['publishedSince'] || '*',
                         filters['publishedBefore'] || 'NOW')
      end
      return unless filters['sizeGreater'] || filters['sizeLesser']

      add_range_filter('dataset_size_l', filters['sizeGreater'] || '*',
                       filters['sizeLesser'] || '*')
    end

    def add_exact_filter(solr_field, value)
      if value.is_a?(Array)
        value.each { |v| @fq_array << "#{solr_field}:\"#{v}\"" }
      elsif value
        @fq_array << "#{solr_field}:\"#{value}\""
      end
    end

    def add_text_filter(solr_field, value)
      if value.is_a?(Array)
        value.each { |v| @fq_array << "#{solr_field}:(#{v})" }
      elsif value
        @fq_array << "#{solr_field}:(#{value})"
      end
    end

    def add_range_filter(solr_field, start_value, end_value)
      @fq_array << "#{solr_field}:[#{start_value} TO #{end_value}]"
    end

    def add_related_work_filter(id, relationship)
      return if id.blank? && relationship.blank?

      q = id.present? ? "id=#{id}" : '*'
      q += relationship.present? ? ",type=#{relationship}" : ',*'

      @fq_array << "rw_sim:#{q}"
    end
  end
end
