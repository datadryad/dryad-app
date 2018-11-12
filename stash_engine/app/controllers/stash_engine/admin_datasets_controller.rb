require_dependency 'stash_engine/application_controller'

module StashEngine
  class AdminDatasetsController < ApplicationController
    include SharedSecurityController
    before_action :require_admin
    before_action :setup_paging

    # the admin datasets main page showing users and stats, but slightly different in scope for superusers vs tenant admins
    def index
      my_tenant_id = (current_user.role == 'admin' ? current_user.tenant_id : nil)
      @all_stats = Stats.new
      @seven_day_stats = Stats.new(tenant_id: my_tenant_id, since: (Time.new - 7.days))

      @ds_identifiers = build_table_query
    end

    private

    def setup_paging
      @page = params[:page] || '1'
      @page_size = (params[:page_size].blank? || params[:page_size] != '1000000' ? '10' : '1000000')
    end

    def build_table_query
      ds_identifiers = base_table_join
      ds_identifiers = ds_identifiers.where('stash_engine_resources.tenant_id = ?', current_user.tenant_id) if current_user.role != 'superuser'
      ds_identifiers.page(@page).per(@page_size)
    end

    def base_table_join
      Identifier.joins([{ latest_resource: :user }, { identifier_state: { curation_activity: :user } }])
    end
  end
end
