require_dependency 'stash_engine/application_controller'

module StashEngine
  class AdminDatasetsController < ApplicationController
    include SharedSecurityController
    before_action :require_admin

    # the admin datasets main page showing users and stats, but slightly different in scope for superusers vs tenant admins
    def index
      my_tenant = ( current_user.role == 'admin' ? current_user.tenant : nil )
      @all_stats = Stats.new #
      @seven_day_stats = Stats.new(tenant_id: my_tenant, since: (Time.new - 7.days) )
    end

    private

  end
end
