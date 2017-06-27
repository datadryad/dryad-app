require_dependency 'stash_engine/application_controller'

module StashEngine
  class AdminController < ApplicationController

    def index
      setup_superuser_stats
      setup_superuser_facets
      @users = User.all
    end

    private

    def setup_superuser_stats
      @stats =
        {
          user_count: User.all.count,
          dataset_count: Identifier.all.count, user_7days: User.where(['created_at > ?', Time.new - 7.days]).count
        }
      setup_7_day_stats
    end

    def setup_7_day_stats
      @stats.merge!(
        dataset_started_7days: Resource.joins(:current_resource_state)
          .where(stash_engine_resource_states: { resource_state: %i[in_progress] })
          .where(['stash_engine_resources.created_at > ?', Time.new - 7.days]).count,
        dataset_submitted_7days: Identifier.where(['created_at > ?', Time.new - 7.days]).count
      )
    end

    def setup_superuser_facets
      @tenant_facets = StashEngine::Tenant.all.sort_by(&:short_name)
      @user_facets = User.all.order(last_name: :asc)
    end
  end
end
