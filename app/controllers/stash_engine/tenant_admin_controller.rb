module StashEngine
  class TenantAdminController < ApplicationController
    helper SortableTableHelper
    before_action :require_user_login
    before_action :require_superuser
    before_action :setup_paging, only: %i[index]

    def index
      setup_sponsors

      @tenants = StashEngine::Tenant.all

      if params[:q]
        q = params[:q]
        # search the query in any searchable field
        @tenants = @tenants.where('short_name LIKE ? OR long_name LIKE ? OR id LIKE ?',
                                  "%#{q}%", "%#{q}%", "%#{q}%")
      end

      ord = helpers.sortable_table_order(whitelist: %w[id short_name long_name partner_display enabled])
      @tenants = @tenants.order(ord)

      @tenants = @tenants.where('id = ? or sponsor_id= ?', params[:sponsor], params[:sponsor]) if params[:sponsor].present?

      # paginate for display
      @tenants = @tenants.page(@page).per(@page_size)
    end

    private

    def setup_paging
      @page = params[:page] || '1'
      @page_size = if params[:page_size].blank? || params[:page_size].to_i == 0
                     10
                   else
                     params[:page_size].to_i
                   end
    end

    def setup_sponsors
      @sponsors = [OpenStruct.new(id: '', name: '*Select institution*')]
      @sponsors << StashEngine::Tenant.sponsored.map { |t| OpenStruct.new(id: t.id, name: t.short_name) }
      @sponsors.flatten!
    end

  end
end
