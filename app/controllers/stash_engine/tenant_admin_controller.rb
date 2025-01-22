module StashEngine
  class TenantAdminController < ApplicationController
    helper SortableTableHelper
    before_action :require_user_login
    before_action :setup_paging, only: :index

    def index
      authorize %i[stash_engine tenant], :admin?
      setup_consortia

      @tenants = StashEngine::Tenant

      if params[:q]
        q = params[:q]
        # search the query in any searchable field
        @tenants = @tenants.where('LOWER(short_name) LIKE LOWER(?) OR LOWER(long_name) LIKE LOWER(?) OR LOWER(stash_engine_tenants.id) LIKE LOWER(?)',
                                  "%#{q}%", "%#{q}%", "%#{q}%")
      end

      ord = helpers.sortable_table_order(whitelist: %w[id short_name long_name authentication covers_dpc partner_display enabled])
      @tenants = @tenants.order(ord)

      if params[:consortium].present?
        rors = StashEngine::Tenant.find(params[:consortium]).ror_ids
        @tenants = @tenants.joins(:tenant_ror_orgs).where(tenant_ror_orgs: { ror_id: rors }).distinct
      end

      # paginate for display
      @tenants = @tenants.includes(%i[logo ror_orgs]).page(@page).per(@page_size)
    end

    def edit
      @tenant = authorize StashEngine::Tenant.find(params[:id])
      respond_to(&:js)
    end

    def update
      @tenant = authorize StashEngine::Tenant.find(params[:id])
      @tenant.update(update_hash)
      update_associations
      respond_to(&:js)
    end

    def new
      @tenant = authorize StashEngine::Tenant.new
      respond_to(&:js)
    end

    def create
      h = update_hash
      h[:id] = edit_params[:id]
      @tenant = StashEngine::Tenant.create(h)
      update_associations
      redirect_to action: 'index', q: edit_params[:id]
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

    def setup_consortia
      @consortia = [OpenStruct.new(id: '', name: '')]
      rors = StashEngine::TenantRorOrg.select(:ror_id).group(:ror_id).having('count(ror_id) > 1')
      tenants = StashEngine::Tenant.includes([:tenant_ror_orgs]).joins(:tenant_ror_orgs).where(tenant_ror_orgs: { ror_id: rors })
        .distinct.order(:short_name)
      tenants.each do |t|
        if t.tenant_ror_orgs.length > 1 &&
          StashEngine::Tenant.joins(:tenant_ror_orgs).where(tenant_ror_orgs: { ror_id: t.ror_ids }).distinct.length > 2
          @consortia << OpenStruct.new(id: t.id, name: t.short_name)
        end
      end
      @consortia.flatten!
    end

    def update_hash
      valid = %i[covers_dpc partner_display enabled short_name long_name sponsor_id]
      update = edit_params.slice(*valid)
      update[:sponsor_id] = nil if edit_params.key?(:sponsor_id) && edit_params[:sponsor_id].blank?
      update[:campus_contacts] = edit_params[:campus_contacts].split("\n").map(&:strip).to_json if edit_params.key?(:campus_contacts)
      if edit_params.key?(:authentication)
        auth = {
          strategy: edit_params[:authentication][:strategy],
          ranges: edit_params[:authentication][:ranges].present? ? edit_params[:authentication][:ranges].split("\n").map(&:strip) : nil,
          entity_id: edit_params[:authentication][:entity_id].presence || nil,
          entity_domain: edit_params[:authentication][:entity_domain].presence || nil
        }
        update[:authentication] = auth.compact.to_json
      end
      update
    end

    def update_associations
      if edit_params.key?(:logo) && edit_params[:logo] != @tenant.logo&.data
        @tenant.logo = StashEngine::Logo.new unless @tenant.logo.present?
        @tenant.logo.data = edit_params[:logo]
        @tenant.logo.save
      end

      if edit_params.key?(:ror_orgs)
        orgs = edit_params[:ror_orgs].split("\n")
        if @tenant.ror_ids.difference(orgs).any?
          @tenant.tenant_ror_orgs.destroy_all
          orgs.each { |o| StashEngine::TenantRorOrg.create(ror_id: o.strip, tenant_id: @tenant.id) }
        end
      end

      @tenant.reload
    end

    def edit_params
      params.permit(:id, :short_name, :long_name, :logo, :campus_contacts, :covers_dpc, :partner_display, :enabled, :ror_orgs, :sponsor_id,
                    authentication: %i[strategy ranges entity_id entity_domain])
    end

  end
end
