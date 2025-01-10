module StashEngine
  class JournalOrganizationAdminController < ApplicationController
    helper SortableTableHelper
    before_action :require_user_login
    before_action :setup_paging, only: :index
    before_action :load, only: %i[popup edit]

    def index
      setup_sponsors

      @orgs = authorize StashEngine::JournalOrganization.includes(%i[children parent_org])

      if params[:q]
        q = params[:q]
        # search the query in any searchable field
        @orgs = @orgs.where('LOWER(name) LIKE LOWER(?)', "%#{q}%")
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
      @org.update(update_hash)
      respond_to(&:js)
    end

    def new
      @org = authorize StashEngine::JournalOrganization.new
      respond_to(&:js)
    end

    def create
      @org = StashEngine::JournalOrganization.create(update_hash)
      redirect_to action: 'index', q: @org.name
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
      @sponsors = [OpenStruct.new(id: '', name: '')]
      @sponsors << StashEngine::JournalOrganization.has_children.order(:name).map { |o| OpenStruct.new(id: o.id, name: o.name) }
      @sponsors.flatten!
    end

    def update_hash
      valid = %i[name parent_org_id]
      update = edit_params.slice(*valid)
      update[:parent_org_id] = nil if edit_params.key?(:parent_org_id) && edit_params[:parent_org_id].blank?
      update[:contact] = edit_params[:contact].split("\n").map(&:strip).to_json if edit_params[:contact]
      update
    end

    def load
      @org = authorize StashEngine::JournalOrganization.find(params[:id]), :popup?
      @field = params[:field]
    end

    def edit_params
      params.permit(:id, :field, :name, :contact, :parent_org_id)
    end

  end
end
