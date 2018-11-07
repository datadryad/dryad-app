require_dependency 'stash_engine/application_controller'

module StashEngine
  class AdminDatasetsController < ApplicationController
    include SharedSecurityController
    before_action :require_admin
    before_action :setup_paging

    # the admin datasets main page showing users and stats, but slightly different in scope for superusers vs tenant admins
    def index
      my_tenant = (current_user.role == 'admin' ? current_user.tenant : nil)
      @all_stats = Stats.new
      @seven_day_stats = Stats.new(tenant_id: my_tenant, since: (Time.new - 7.days))

      # these options are added by kaminari for paging
      @ds_identifiers = Identifier.page(@page).per(@page_size)
    end

    private

    def setup_paging
      @page = params[:page] || '1'
      @page_size = (params[:page_size].blank? || params[:page_size] != '1000000' ? '10' : '1000000')
    end
  end
end
