# frozen_string_literal: true

# This is NOT an ActiveRecord model and does not persist data!!
# This class represents a row in the Admin's Curation page. It only retrieves the information
# necessary to populate the table on that page.
module StashEngine
  module AdminDatasets
    class CurationTableRow

      attr_reader :publication_name
      attr_reader :identifier_id, :identifier, :storage_size, :search_words
      attr_reader :resource_id, :title, :publication_date, :tenant_id
      attr_reader :resource_state_id, :resource_state
      attr_reader :curation_activity_id, :status, :updated_at
      attr_reader :editor_id, :editor_name
      attr_reader :author_names
      attr_reader :relevance

      SELECT_CLAUSE = <<-SQL
        SELECT seid.value,
          sei.id, sei.identifier, sei.storage_size, sei.search_words,
          ser.id, ser.title, ser.publication_date, ser.tenant_id,
          sers.id, sers.resource_state,
          seca.id, seca.status, seca.updated_at,
          seu.id, seu.last_name, seu.first_name,
          (SELECT GROUP_CONCAT(DISTINCT sea.author_last_name ORDER BY sea.author_last_name SEPARATOR '; ')
           FROM stash_engine_authors sea
           WHERE sea.resource_id = ser.id)
      SQL

      FROM_CLAUSE = <<-SQL
          FROM stash_engine_resources ser
          LEFT OUTER JOIN stash_engine_identifiers sei ON ser.identifier_id = sei.id
          LEFT OUTER JOIN stash_engine_internal_data seid ON sei.id = seid.identifier_id AND seid.data_type = 'publicationName'
          LEFT OUTER JOIN stash_engine_users seu ON ser.current_editor_id = seu.id
          INNER JOIN (SELECT MAX(r2.id) r_id FROM stash_engine_resources r2 GROUP BY r2.identifier_id) j1 ON j1.r_id = ser.id
          LEFT OUTER JOIN (SELECT rs2.resource_id, MAX(rs2.id) latest_resource_state_id FROM stash_engine_resource_states rs2 GROUP BY rs2.resource_id) j2 ON j2.resource_id = ser.id
          LEFT OUTER JOIN (SELECT ca2.resource_id, MAX(ca2.id) latest_curation_activity_id FROM stash_engine_curation_activities ca2 GROUP BY ca2.resource_id) j3 ON j3.resource_id = ser.id
          LEFT OUTER JOIN stash_engine_resource_states sers ON sers.id = j2.latest_resource_state_id
          LEFT OUTER JOIN stash_engine_curation_activities seca ON seca.id = j3.latest_curation_activity_id
      SQL

      SEARCH_CLAUSE = 'MATCH(sei.search_words) AGAINST(%{term}) > 05'
      SCAN_CLAUSE = 'sei.search_words LIKE %{term}'
      TENANT_CLAUSE = 'ser.tenant_id = %{term}'
      STATUS_CLAUSE = 'seca.status = %{term}'
      PUBLICATION_CLAUSE = 'seid.value = %{term}'

      # rubocop:disable Metrics/AbcSize
      def initialize(result)
        return unless result.is_a?(Array) && result.length >= 18

        # Convert the array of results into attribute values
        @publication_name = result[0]
        @identifier_id = result[1]
        @identifier = result[2]
        @storage_size = result[3]
        @search_words = result[4]
        @resource_id = result[5]
        @title = result[6]
        @publication_date = result[7]
        @tenant_id = result[8]
        @resource_state_id = result[9]
        @resource_state = result[10]
        @curation_activity_id = result[11]
        @status = result[12]
        @updated_at = result[13]
        @editor_id = result[14]
        @editor_name = result[15..16].join(', ')
        @author_names = result[17]
        @relevance = result.length > 18 ? result[18] : nil
      end
      # rubocop:enable Metrics/AbcSize

      class << self

        def where(params)
          return [] unless params.is_a?(Hash)

          # If a search term was provided include the relevance score in the results for sorting purposes
          relevance = params.fetch(:q, '').blank? ? '' : ", (#{add_term_to_clause(SEARCH_CLAUSE, params.fetch(:q, ''))}) relevance"
          # editor_name is derived from 2 DB fields so use the last_name instead
          column = (params.fetch(:sort, '') == 'editor_name' ? 'last_name' : params.fetch(:sort, ''))

          query = " \
            #{SELECT_CLAUSE}
            #{relevance}
            #{FROM_CLAUSE}
            #{build_where_clause(params.fetch(:q, ''), params.fetch(:tenant_id, ''), params.fetch(:curation_status, ''),
                                 params.fetch(:publication_name, ''))}
            #{build_order_clause(params.fetch(:q, '').present?, column, params.fetch(:direction, ''))}
          "
          results = ActiveRecord::Base.connection.execute(query).map { |result| new(result) }
          # If the user is trying to sort by author names, then
          (column == 'author_names' ? sort_by_author_names(results, params.fetch(:direction, '')) : results)
        end

        private

        # Create the WHERE portion of the query based on the filters set by the user (if any)
        def build_where_clause(search_term, tenant_filter, status_filter, publication_filter)
          where_clause = [
            (search_term.present? ? build_search_clause(search_term) : nil),
            add_term_to_clause(TENANT_CLAUSE, tenant_filter),
            add_term_to_clause(STATUS_CLAUSE, status_filter),
            add_term_to_clause(PUBLICATION_CLAUSE, publication_filter)
          ].compact
          where_clause.empty? ? '' : " WHERE #{where_clause.join(' AND ')}"
        end

        # Build the WHERE portion of the query for the specified search term (if any)
        def build_search_clause(term)
          return '' unless term.present?
          "((#{add_term_to_clause(SEARCH_CLAUSE, term)}) OR #{add_term_to_clause(SCAN_CLAUSE, "%#{term}%")})"
        end

        # Create the ORDER BY portion of the query. If the user included a search term order by relevance first!
        # We cannot sort by author_names here, so ignore if that is the :sort_column
        def build_order_clause(searching, column, direction)
          order_by = [
            (searching ? 'relevance DESC' : nil),
            (column.present? && column != 'author_names' ? "#{column} #{direction || 'ASC'}" : nil)
          ].compact
          order_by.empty? ? '' : "ORDER BY #{order_by.join(', ')}"
        end

        def sort_by_author_names(results, direction)
          return results.sort { |a, b| b.author_names.downcase <=> a.author_names.downcase } if direction.casecmp('desc').zero?
          results.sort { |a, b| a.author_names.downcase <=> b.author_names.downcase }
        end

        # Swap a term into the SQL snippet/clause
        def add_term_to_clause(clause, term)
          return nil unless clause.present? && term.present?
          format(clause.to_s, term: ActiveRecord::Base.connection.quote(term))
        end

      end

    end
  end
end
