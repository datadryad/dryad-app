module StashEngine
  class JournalOrganizationAdminController < ApplicationController
    helper SortableTableHelper
    before_action :require_user_login
    before_action :require_superuser
    before_action :setup_paging, only: :index
    before_action :load, only: %i[popup edit]

    def index
      setup_sponsors

      @orgs = StashEngine::JournalOrganization.all

      if params[:q]
        q = params[:q]
        # search the query in any searchable field
        @orgs = @orgs.where('name LIKE ?', "%#{q}%")
      end

      ord = helpers.sortable_table_order(whitelist: %w[name])
      @orgs = @orgs.order(ord)

      @orgs = @orgs.where('parent_org_id= ?', params[:sponsor]) if params[:sponsor].present?

      # paginate for display
      @orgs = @orgs.page(@page).per(@page_size)
    end

    def popup
      strings = { name: 'name', contact: 'contacts', parent_org_id: 'parent organization' }
      @desc = strings[@field.to_sym]
      respond_to(&:js)
    end

    def edit
      valid = %i[name parent_org_id]
      update = edit_params.slice(*valid)
      update[:parent_org_id] = nil if edit_params[:parent_org_id].blank?
      update[:contact] = edit_params[:contact].split("\n").map(&:strip).to_json if edit_params[:contact]
      @org.update(update)

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
      @sponsors = [OpenStruct.new(id: '', name: '*Select publisher*')]
      @sponsors << StashEngine::JournalOrganization.has_children.map { |o| OpenStruct.new(id: o.id, name: o.name) }
      @sponsors.flatten!
    end

    def load
      @org = authorize StashEngine::JournalOrganization.find(params[:id]), :load?
      @field = params[:field]
    end

    def edit_params
      params.permit(:id, :field, :name, :contact, :parent_org_id)
    end

  end
end
