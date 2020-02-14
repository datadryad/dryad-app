# frozen_string_literal: true

# This is NOT an ActiveRecord model and does not persist data!!
# This class represents a row in the Admin's Curation page. It only retrieves the information
# necessary to populate the table on that page.

# rubocop:disable Metrics/ClassLength
module StashEngine
  module AdminDatasets
    class CurationTableRow

      attr_reader :publication_name
      attr_reader :identifier_id, :identifier, :qualified_identifier, :storage_size, :search_words
      attr_reader :resource_id, :title, :publication_date, :tenant_id
      attr_reader :resource_state_id, :resource_state
      attr_reader :curation_activity_id, :status, :updated_at
      attr_reader :editor_id, :editor_name
      attr_reader :author_names
      attr_reader :views, :downloads, :citations
      attr_reader :relevance

      SELECT_CLAUSE = <<-SQL
        SELECT DISTINCT seid.value,
          sei.id, sei.identifier, CONCAT(LOWER(sei.identifier_type), ':', sei.identifier), sei.storage_size, sei.search_words,
          ser.id, ser.title, ser.publication_date, ser.tenant_id,
          sers.id, sers.resource_state,
          seca.id, seca.status, seca.updated_at,
          seu.id, seu.last_name, seu.first_name,
          (SELECT GROUP_CONCAT(DISTINCT sea.author_last_name ORDER BY sea.author_last_name SEPARATOR '; ')
           FROM stash_engine_authors sea
           WHERE sea.resource_id = ser.id),
          secs.unique_investigation_count, secs.unique_request_count, secs.citation_count
      SQL

      FROM_CLAUSE = <<-SQL
          FROM stash_engine_resources ser
          INNER JOIN stash_engine_identifiers sei ON ser.identifier_id = sei.id
          LEFT OUTER JOIN stash_engine_internal_data seid ON sei.id = seid.identifier_id AND seid.data_type = 'publicationName'
          LEFT OUTER JOIN stash_engine_users seu ON ser.current_editor_id = seu.id
          INNER JOIN (SELECT MAX(r2.id) r_id FROM stash_engine_resources r2 GROUP BY r2.identifier_id) j1 ON j1.r_id = ser.id
          LEFT OUTER JOIN (SELECT rs2.resource_id, MAX(rs2.id) latest_resource_state_id FROM stash_engine_resource_states rs2 GROUP BY rs2.resource_id) j2 ON j2.resource_id = ser.id
          LEFT OUTER JOIN (SELECT ca2.resource_id, MAX(ca2.id) latest_curation_activity_id FROM stash_engine_curation_activities ca2 GROUP BY ca2.resource_id) j3 ON j3.resource_id = ser.id
          LEFT OUTER JOIN stash_engine_resource_states sers ON sers.id = j2.latest_resource_state_id
          LEFT OUTER JOIN stash_engine_curation_activities seca ON seca.id = j3.latest_curation_activity_id
          LEFT OUTER JOIN stash_engine_counter_stats secs ON sei.id = secs.identifier_id
      SQL

      # add extra joins when I need to reach into author affiliations for ever dataset
      FROM_CLAUSE_ADMIN = <<-SQL
        #{FROM_CLAUSE}
        LEFT OUTER JOIN stash_engine_authors sea2 ON ser.id = sea2.resource_id
        LEFT OUTER JOIN dcs_affiliations_authors dcs_aa ON sea2.id = dcs_aa.author_id
        LEFT OUTER JOIN dcs_affiliations dcs_a ON dcs_aa.affiliation_id = dcs_a.id
      SQL

      SEARCH_CLAUSE = 'MATCH(sei.search_words) AGAINST(%{term})'
      BOOLEAN_SEARCH_CLAUSE = 'MATCH(sei.search_words) AGAINST(%{term} IN BOOLEAN MODE)'
      SCAN_CLAUSE = 'sei.search_words LIKE %{term}'
      TENANT_CLAUSE = 'ser.tenant_id = %{term}'
      STATUS_CLAUSE = 'seca.status = %{term}'
      PUBLICATION_CLAUSE = 'seid.value = %{term}'

      # this method is long, but quite uncomplicated as it mostly just sets variables from the query
      #
      # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength
      def initialize(result)
        return unless result.is_a?(Array) && result.length >= 22

        # Convert the array of results into attribute values
        @publication_name = result[0]
        @identifier_id = result[1]
        @identifier = result[2]
        @qualified_identifier = result[3]
        @storage_size = result[4]
        @search_words = result[5]
        @resource_id = result[6]
        @title = result[7]
        @publication_date = result[8]
        @tenant_id = result[9]
        @resource_state_id = result[10]
        @resource_state = result[11]
        @curation_activity_id = result[12]
        @status = result[13]
        @updated_at = result[14]
        @editor_id = result[15]
        @editor_name = result[16..17].join(', ')
        @author_names = result[18]
        @views = (result[20].nil? ? 0 : result[19] - result[20])
        @downloads = result[20] || 0
        @citations = result[21] || 0
        @relevance = result.length > 22 ? result[22] : nil
      end
      # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength
      #

      # lets you get a resource when you need it and caches it
      def resource
        @resource ||= StashEngine::Resource.find_by(id: @resource_id)
      end

      class << self

        # params are params from the form.
        # The tenant, if set, does two things in conjunction.  it limits to items with a tenant_id of the tenant OR
        # affiliated author institution RORs (may be multiple) for this tenant with additional joins and conditions.
        # tenant is only set for admins (not superusers).
        def where(params:, tenant: nil)
          return [] unless params.is_a?(Hash)

          # If a search term was provided include the relevance score in the results for sorting purposes
          relevance = params.fetch(:q, '').blank? ? '' : ", (#{add_term_to_clause(SEARCH_CLAUSE, params.fetch(:q, ''))}) relevance"
          # editor_name is derived from 2 DB fields so use the last_name instead
          column = (params.fetch(:sort, '') == 'editor_name' ? 'last_name' : params.fetch(:sort, ''))

          query = " \
            #{SELECT_CLAUSE}
            #{relevance}
            #{(tenant ? FROM_CLAUSE_ADMIN : FROM_CLAUSE)}
            #{build_where_clause(search_term: params.fetch(:q, ''),
                                 all_advanced: params.fetch(:all_advanced, false),
                                 tenant_filter: params.fetch(:tenant, ''),
                                 status_filter: params.fetch(:curation_status, ''),
                                 publication_filter: params.fetch(:publication_name, ''),
                                 admin_tenant: tenant)}
            #{build_order_clause(column, params.fetch(:direction, ''), params.fetch(:q, ''))}
          "
          results = ActiveRecord::Base.connection.execute(query).map { |result| new(result) }
          # If the user is trying to sort by author names, then
          (column == 'author_names' ? sort_by_author_names(results, params.fetch(:direction, '')) : results)
        end

        private

        # Create the WHERE portion of the query based on the filters set by the user (if any)
        # rubocop:disable Metrics/ParameterLists
        def build_where_clause(search_term:, all_advanced:, tenant_filter:, status_filter:, publication_filter:, admin_tenant:)
          where_clause = [
            (search_term.present? ? build_search_clause(search_term, all_advanced) : nil),
            add_term_to_clause(TENANT_CLAUSE, tenant_filter),
            add_term_to_clause(STATUS_CLAUSE, status_filter),
            add_term_to_clause(PUBLICATION_CLAUSE, publication_filter),
            create_tenant_limit(admin_tenant)
          ].compact
          where_clause.empty? ? '' : " WHERE #{where_clause.join(' AND ')}"
        end
        # rubocop:enable Metrics/ParameterLists

        # Build the WHERE portion of the query for the specified search term (if any)
        def build_search_clause(term, all_advanced)
          return '' unless term.present?

          if all_advanced == '1'
            "(#{add_term_to_clause(BOOLEAN_SEARCH_CLAUSE, advanced_search(term))})"
          else
            "(#{add_term_to_clause(SEARCH_CLAUSE, term)})"
          end
        end

        # If someone is choosing 'all words' then default to boolean search and determine if they're using common
        # modifiers, and if so just pass it through because they are likely a special person who knows what they're doing,
        # otherwise add plusses to all their words to make them required internally
        def advanced_search(terms)
          if /[~+<>*]/.match?(terms)
            terms
          else
            terms&.split&.map { |i| "+\"#{i}\"" }&.join(' ')
          end
        end

        # Create the ORDER BY portion of the query. If the user included a search term order by relevance first!
        # We cannot sort by author_names here, so ignore if that is the :sort_column
        # rubocop:disable Metrics/CyclomaticComplexity
        def build_order_clause(column, direction, q)
          return 'ORDER BY title' if column == 'relevance' && q.blank?

          if column == 'relevance'
            'ORDER BY relevance DESC'
          else
            (column.present? && column != 'author_names' ? "ORDER BY #{column} #{direction || 'ASC'}" : '')
          end
        end
        # rubocop:enable Metrics/CyclomaticComplexity

        def sort_by_author_names(results, direction)
          multiply_by = (direction.casecmp('desc').zero? ? -1 : 1)
          results.sort { |a, b| multiply_by * ((a&.author_names&.downcase || '') <=> (b&.author_names&.downcase || '')) }
        end

        # Swap a term into the SQL snippet/clause
        def add_term_to_clause(clause, term)
          return nil unless clause.present? && term.present?
          format(clause.to_s, term: ActiveRecord::Base.connection.quote(term))
        end

        def create_tenant_limit(admin_tenant)
          return nil if admin_tenant.blank?

          ActiveRecord::Base.send(:sanitize_sql_array, ['( ser.tenant_id = ? OR dcs_a.ror_id IN (?) )', admin_tenant.tenant_id,
                                                        admin_tenant.ror_ids])
        end
      end

    end
  end
end
# rubocop:enable Metrics/ClassLength
