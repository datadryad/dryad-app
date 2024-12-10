module StashApi
  class SolrSearchService
    attr_reader :query, :filters
    attr_accessor :error

    def initialize(query:, filters:)
      @query   = query
      @filters = filters
      @error   = nil

      @solr = RSolr.connect(url: Blacklight.connection_config[:url])
      parse_query
    end

    def search(page: 1, per_page: DEFAULT_PAGE_SIZE)
      solr_call = @solr.paginate(page, per_page, 'select',
                                 params: { q: query.to_s, fq: filter_query, fl: 'dc_identifier_s' })
      solr_call['response']
    rescue RSolr::Error::Http
      @error = OpenStruct.new(status: 400, message: 'Unable to parse query request.')
      []
    end

    private

    def parse_query
      # do some light sanitization
      # passing `system(_any_string_)` or `exec(_any_string_)` will return a 403 from solr
      # escaping these as `system\(_any_string_\)` will perform the query as expected
      @query = query&.gsub(/.*\(.*?\).*/) { |match| match.gsub('(', '\(').gsub(')', '\)') }
    end

    # Builds an array of the various filter settings requested
    def filter_query
      @fq_array = []

      # if user requests both 'affiliation' and 'tenant', prefer the affiliation,
      # because it is more specific
      if filters['affiliation']
        add_text_filter('dryad_author_affiliation_id_sm', filters['affiliation'])
      elsif filters['tenant']
        # multiple affiliations, separated by OR
        if StashEngine::Tenant.exists?(filters['tenant'])
          tenant = StashEngine::Tenant.find(filters['tenant'])
          ror_array = tenant.ror_ids.map do |r|
            # map the id into the format
            "dryad_author_affiliation_id_sm:\"#{r}\" "
          end
          @fq_array << ror_array.join(' OR ')
        else
          add_text_filter('dryad_author_affiliation_id_sm', 'missing_tenant')
        end
      end

      add_date_filter('updated_at_dt', filters['modifiedSince'], 'NOW') if filters['modifiedSince']
      add_date_filter('updated_at_dt', '*', filters['modifiedBefore']) if filters['modifiedBefore']
      add_text_filter('dryad_related_publication_issn_s', filters['journalISSN'])
      add_related_work_filter(filters['relatedWorkIdentifier'], filters['relatedWorkRelationship'])

      @fq_array
    end

    def add_text_filter(solr_field, value)
      @fq_array << "#{solr_field}:\"#{value}\"" if value
    end

    def add_date_filter(solr_field, start_value, end_value)
      @fq_array << "#{solr_field}:[#{start_value} TO #{end_value}]"
    end

    def add_related_work_filter(id, relationship)
      return if id.blank? && relationship.blank?

      query = id.present? ? "id=#{id}" : '*'
      query += relationship.present? ? ",type=#{relationship}" : ',*'

      @fq_array << "rw_sim:#{query}"
    end
  end
end
