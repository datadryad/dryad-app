# trying to organize like http://vrybas.github.io/blog/2014/08/15/a-way-to-organize-poros-in-rails/ to keep things less cluttered
module StashEngine
  class AdminDatasetsController
    class Stats

      PREHISTORIC_TIME = Time.new(-60_000, 1, 1).utc

      # leave tenant_id blank if you want stats for all
      def initialize(tenant_id: nil, since: PREHISTORIC_TIME)
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
        datasets_with_status_count(status: 'in_progress')
      end

      def datasets_submitted_count
        datasets_with_status_count(status: 'submitted')
      end

      private

      def datasets_with_status_count(status:)
        ident_query = Identifier.where(['stash_engine_identifiers.created_at > ?', @since]).joins(latest_resource: :current_resource_state)
        ident_query = ident_query.where(['stash_engine_resources.tenant_id = ?', @tenant_id]) if @tenant_id
        ident_query = ident_query.where(['stash_engine_resource_states.resource_state = ?', status])
        ident_query.count
      end

    end
  end
end
