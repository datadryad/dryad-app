module Integrations
  class NIH < Integrations::Base
    BASE_URL       = 'https://api.reporter.nih.gov/v2/'.freeze
    DEFAULT_LIMIT  = 50
    MAX_LIMIT      = 500
    DEFAULT_FIELDS = %w[ProjectTitle ProjectNum AgencyIcFundings AgencyIcAdmin ProjectDetailUrl CoreProjectNum DateAdded].freeze

    def search_awards(award_ids)
      # should be searching by core_project_nums, but the API returns too many results
      results = search(criteria: { project_nums: award_ids }, sort_field: 'DateAdded', sort_order: 'desc')
      return [] if results.blank?

      results['results']
    end

    # Performs a search with given criteria.
    # Params:
    # - criteria: a hash of criteria keys/values per API spec
    # - offset: integer, default 0
    # - limit: integer, default DEFAULT_LIMIT, must be <= MAX_LIMIT
    # - sort_field: string (optional)
    # - sort_order: string, 'asc' or 'desc' (optional)
    #
    # Returns: parsed JSON (a hash with "results" and metadata) or raises StandardError
    def search(criteria: {}, offset: 0, limit: DEFAULT_LIMIT, sort_field: nil, sort_order: 'asc')
      raise ArgumentError, "limit must be <= #{MAX_LIMIT}" if limit > MAX_LIMIT
      raise ArgumentError, 'offset must be >= 0' if offset < 0
      raise ArgumentError, "sort_order must be 'asc' or 'desc'" unless sort_order.nil? || %w[asc desc].include?(sort_order)

      payload              = {
        criteria: criteria,
        include_fields: DEFAULT_FIELDS
      }
      payload[:offset]     = offset if offset
      payload[:limit]      = limit if limit
      payload[:sort_field] = sort_field if sort_field
      payload[:sort_order] = sort_order if sort_field

      post_json("#{BASE_URL}projects/search", payload)
    end
  end
end
