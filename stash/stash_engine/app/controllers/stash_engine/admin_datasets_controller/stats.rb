# trying to organize like http://vrybas.github.io/blog/2014/08/15/a-way-to-organize-poros-in-rails/ to keep things less cluttered
module StashEngine
  class AdminDatasetsController
    class Stats

      START_OF_AD_TIME = Time.new(0, 1, 1).utc

      STATUS_QUERY_BASE = <<-SQL.freeze
           SELECT count(*)
           FROM stash_engine_resources ser
             INNER JOIN stash_engine_identifiers sei ON ser.identifier_id = sei.id
             INNER JOIN (SELECT MAX(r2.id) r_id FROM stash_engine_resources r2 GROUP BY r2.identifier_id) j1 ON j1.r_id = ser.id
             LEFT OUTER JOIN (SELECT ca2.resource_id, MAX(ca2.id) latest_curation_activity_id FROM stash_engine_curation_activities ca2 GROUP BY ca2.resource_id) j3 ON j3.resource_id = ser.id
             LEFT OUTER JOIN stash_engine_curation_activities seca ON seca.id = j3.latest_curation_activity_id
      SQL

      # leave tenant_id blank if you want stats for all
      def initialize(tenant_id: nil, since: START_OF_AD_TIME)
        @tenant_id = tenant_id
        @since = since
      end

      # it seems like ActiveRecord caches queries so, not sure I need to cache this
      def user_count
        user_query = User.where(['created_at > ?', @since])
        user_query = user_query.where(tenant_id: @tenant_id) unless @tenant_id.nil?
        user_query.count
      end

      def dataset_count
        ident_query = Identifier.where(['stash_engine_identifiers.created_at > ?', @since])
        ident_query = ident_query.joins(:latest_resource).where(['stash_engine_resources.tenant_id = ?', @tenant_id]) if @tenant_id
        ident_query.count
      end

      def datasets_started_count
        datasets_with_resource_state_count(state: 'in_progress')
      end

      def datasets_submitted_count
        datasets_with_resource_state_count(state: 'submitted')
      end

      def datasets_available_for_curation
        datasets_with_curation_status_count(status: 'submitted') +
          datasets_with_curation_status_count(status: 'curation')
      end

      private

      def datasets_with_resource_state_count(state:)
        ident_query = Identifier.where(['stash_engine_identifiers.created_at > ?', @since]).joins(latest_resource: :current_resource_state)
        ident_query = ident_query.where(['stash_engine_resources.tenant_id = ?', @tenant_id]) if @tenant_id
        ident_query = ident_query.where(['stash_engine_resource_states.resource_state = ?', state])
        ident_query.count
      end

      def datasets_with_curation_status_count(status:)
        query = "#{STATUS_QUERY_BASE} WHERE ser.updated_at > '#{@since}' AND seca.status = '#{status}'"
        ApplicationRecord.connection.execute(query)&.first&.first
      end

    end
  end
end
