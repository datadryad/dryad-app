# trying to organize like http://vrybas.github.io/blog/2014/08/15/a-way-to-organize-poros-in-rails/ to keep things less cluttered
module StashEngine
  class AdminDatasetsController
    class Stats

      START_OF_AD_TIME = '1000-01-01 00:00:00'.freeze

      STATUS_QUERY_BASE = <<-SQL.freeze
           SELECT count(*)
           FROM stash_engine_identifiers sei
             INNER JOIN stash_engine_resources ser ON sei.latest_resource_id = ser.id
             LEFT OUTER JOIN stash_engine_curation_activities seca ON ser.last_curation_activity_id = seca.id
      SQL

      # leave tenant_id blank if you want stats for all
      def initialize(tenant_id: nil, since: START_OF_AD_TIME, untouched_since: Time.now)
        @tenant_id = tenant_id
        @since = since
        @untouched_since = untouched_since
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
        query = "#{STATUS_QUERY_BASE} WHERE ser.updated_at < '#{@untouched_since}' AND ser.created_at > '#{@since}' AND seca.status = '#{status}'"
        ApplicationRecord.connection.execute(query)&.first&.first
      end

    end
  end
end
