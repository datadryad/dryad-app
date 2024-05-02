module StashEngine
  class TenantAdminController < ApplicationController
    helper SortableTableHelper
    before_action :require_user_login
    before_action :require_superuser
    before_action :setup_paging, only: :index
    before_action :load, only: %i[popup edit]

    def index
      setup_sponsors

      @tenants = StashEngine::Tenant.all

      if params[:q]
        q = params[:q]
        # search the query in any searchable field
        @tenants = @tenants.where('short_name LIKE ? OR long_name LIKE ? OR id LIKE ?',
                                  "%#{q}%", "%#{q}%", "%#{q}%")
      end

      ord = helpers.sortable_table_order(whitelist: %w[id short_name long_name authentication partner_display enabled])
      @tenants = @tenants.order(ord)

      @tenants = @tenants.where('id = ? or sponsor_id= ?', params[:sponsor], params[:sponsor]) if params[:sponsor].present?

      # paginate for display
      @tenants = @tenants.page(@page).per(@page_size)
    end

    def popup
      strings = { campus_contacts: 'contacts', partner_display: 'member display', ror_orgs: 'ROR organizations', enabled: 'active membership' }
      @desc = strings[@field.to_sym]
      respond_to(&:js)
    end

    def edit
      valid = %i[partner_display enabled]
      update = edit_params.slice(*valid)
      update[:campus_contacts] = edit_params[:campus_contacts].split("\n").map(&:strip).to_json if edit_params[:campus_contacts]
      @tenant.update(update)

      if edit_params[:ror_orgs]&.present?
        @tenant.tenant_ror_orgs.destroy_all
        orgs = edit_params[:ror_orgs].split("\n")
        orgs.each { |o| StashEngine::TenantRorOrg.create(ror_id: o.strip, tenant_id: @tenant.id) }
        @tenant.reload
      end

      respond_to(&:js)
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

    def load
      @tenant = authorize Tenant.find(params[:id]), :load?
      @field = params[:field]
    end

    def edit_params
      params.permit(:id, :field, :campus_contacts, :partner_display, :enabled, :ror_orgs)
    end

  end
end
