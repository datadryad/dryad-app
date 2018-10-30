require_dependency 'stash_engine/application_controller'

module StashEngine
  class AdminDatasetsController < ApplicationController
    include SharedSecurityController
    before_action :require_admin

    # the admin datasets main page showing users and stats, but slightly different in scope for superusers vs tenant admins
    def index; end

    private

    def setup_stats
      setup_superuser_stats
      limit_to_tenant! if current_user.role == 'admin'
      @stats.each { |k, v| @stats[k] = v.count }
    end

    # TODO: move into models or elsewhere for queries, but can't get tests to run right now so holding off
    def setup_superuser_stats
      @stats =
        {
          user_count: User.all,
          dataset_count: Identifier.all,
          user_7days: User.where(['stash_engine_users.created_at > ?', Time.new - 7.days]),
          dataset_started_7days: Resource.joins(:current_resource_state)
            .where(stash_engine_resource_states: { resource_state: %i[in_progress] })
            .where(['stash_engine_resources.created_at > ?', Time.new - 7.days]),
          dataset_submitted_7days: Identifier.where(['stash_engine_identifiers.created_at > ?', Time.new - 7.days])
        }
    end

    # TODO: move into models or elsewhere for queries, but can't get tests to run right now so holding off
    def limit_to_tenant! # rubocop:disable Metrics/AbcSize
      @stats[:user_count] = @stats[:user_count].where(tenant_id: current_user.tenant_id)
      @stats[:dataset_count] = @stats[:dataset_count].joins(resources: :user)
        .where(['stash_engine_users.tenant_id = ?', current_user.tenant_id]).distinct
      @stats[:user_7days] = @stats[:user_7days].where(tenant_id: current_user.tenant_id)
      @stats[:dataset_started_7days] = @stats[:dataset_started_7days].joins(:user)
        .where(['stash_engine_users.tenant_id = ?', current_user.tenant_id])
      @stats[:dataset_submitted_7days] = @stats[:dataset_submitted_7days].joins(resources: :user)
        .where(['stash_engine_users.tenant_id = ?', current_user.tenant_id]).distinct
    end
  end
end
