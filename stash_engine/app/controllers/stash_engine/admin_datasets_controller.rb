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

      # prepare filter select lists to be used by options_for_select, 1st or key is the text, 2nd is the hidden value in list
      @institution_list = StashEngine::Tenant.all.map{|item| [ item.short_name, item.tenant_id ] }
      @status_list = CurationActivity.validators_on(:status).first.options[:in] # get the list of valid values from model
      byebug
    end

    private

  end
end
