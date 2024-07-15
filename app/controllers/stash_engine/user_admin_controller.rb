require 'kaminari'

module StashEngine
  class UserAdminController < ApplicationController
    helper SortableTableHelper
    before_action :require_user_login
    before_action :load, only: %i[popup edit set_role user_profile]
    before_action :setup_roles, only: %i[set_role user_profile]
    before_action :setup_paging, only: :index

    # the admin_users main page showing users and stats
    def index
      setup_facets
      setup_tenants

      # Default to recently-created users
      if params[:sort].blank? && params[:q].blank?
        params[:sort] = 'created_at'
        params[:direction] = 'desc'
      end

      @users = authorize User.all
      @users = @users.joins(:roles).where(roles: {role: params[:role]}) if params[:role].present?
      @users = @users.where(tenant_id: params[:tenant_id]) if params[:tenant_id].present?

      if params[:q]
        q = params[:q]
        # search the query in any searchable field
        @users = @users.where('LOWER(first_name) LIKE LOWER(?) OR LOWER(last_name) LIKE LOWER(?) OR orcid LIKE ? or LOWER(email) LIKE LOWER(?)',
                              "%#{q}%", "%#{q}%", "%#{q}%", "%#{q}%")
        if q.include?(' ')
          # add any matches for "firstname lastname"
          splitname = q.split
          @users = @users.or(User.where('LOWER(first_name) LIKE LOWER(?) and LOWER(last_name) LIKE LOWER(?)', "%#{splitname.first}%",
                                        "%#{splitname.second}%"))
        end
      end

      ord = helpers.sortable_table_order(whitelist: %w[last_name email tenant_id last_login])
      @users = @users.order(ord)

      add_institution_filter! # if they chose a facet or are only an admin

      # paginate for display
      @users = @users.page(@page).per(@page_size)
    end

    def popup
      authorize %i[stash_engine user]
      strings = { email: 'email', tenant_id: 'member institution' }
      @desc = strings[@field.to_sym]
      respond_to(&:js)
    end

    def edit
      authorize %i[stash_engine user]
      valid = %i[email tenant_id]
      check_tenant_role
      update = edit_params.slice(*valid)
      @user.update(update)

      respond_to(&:js)
    end

    def merge_popup
      authorize %i[stash_engine user]
      selected_users = params['selected_users'].split(',')

      if selected_users.size == 2
        @user1 = StashEngine::User.find(selected_users[0])
        @user2 = StashEngine::User.find(selected_users[1])
      end

      respond_to(&:js)
    end

    def merge
      authorize %i[stash_engine user]
      user1 = StashEngine::User.find(params[:user1])
      user2 = StashEngine::User.find(params[:user2])
      user1.merge_user!(other_user: user2)
      user2.destroy

      respond_to(&:js)
    end

    # sets the user roles
    def set_role
      # set system role
      save_role(role_params[:role], @system_role)
      # set tenant role
      save_role(role_params[:tenant_role], @tenant_role, @user.tenant)
      # set publisher role
      save_role(role_params[:publisher_role], @publisher_role, StashEngine::JournalOrganization.find_by(id: role_params[:publisher]))
      # set journal role
      save_role(role_params[:journal_role], @journal_role, StashEngine::Journal.find_by(id: role_params.dig(:journal, :value)))
      # set funder role
      save_role(role_params[:funder_role], @funder_role, StashEngine::Funder.find_by(id: role_params[:funder]))
      # reload roles
      setup_roles
      respond_to(&:js)
    end

    # profile for a user showing stats and datasets
    def user_profile
      @user = User.find(params[:id])
      @progress_count = Resource.in_progress.where(user_id: @user.id).count
      # some of these columns are calculated values for display that aren't stored (publication date)
      @resources = Resource.where(user_id: @user.id).latest_per_dataset
      @presenters = @resources.map { |res| StashDatacite::ResourcesController::DatasetPresenter.new(res) }
      setup_ds_status_facets
      sort_and_paginate_datasets
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

    def load
      @user = User.find(params[:id])
      @field = params[:field]
    end

    def setup_roles
      @system_role = @user.roles.where(role_object_type: nil)&.first
      @tenant_role = @user.roles.tenant_roles&.first
      @journal_role = @user.roles.journal_roles&.first
      @publisher_role = @user.roles.journal_org_roles&.first
      @funder_role = @user.roles.funder_roles&.first
    end

    def save_role(role, existing, object = nil)
      if role.blank?
        existing.delete if existing
      elsif existing
        existing.update(role: role, role_object: object)
      else
        StashEngine::Role.create(user: @user, role: role, role_object: object)
      end
    end

    def check_tenant_role
      return unless edit_params[:tenant_id] != @user.tenant_id

      @user.roles.tenant_roles.delete_all
      setup_roles
    end

    def setup_ds_status_facets
      @status_facets = @presenters.map(&:embargo_status).uniq.sort
      return unless params[:status]

      @presenters.keep_if { |i| i.embargo_status == params[:status] }
    end

    def sort_and_paginate_datasets
      @page_presenters = Kaminari.paginate_array(@presenters).page(@page).per(@page_size)
    end

    def setup_facets
      @tenant_facets = StashEngine::Tenant.enabled.sort_by(&:short_name)
    end

    def setup_tenants
      @tenants = [OpenStruct.new(id: '', name: '')]
      @tenants << StashEngine::Tenant.enabled.map do |t|
        OpenStruct.new(id: t.id, name: t.short_name)
      end
      @tenants.flatten!
    end

    def add_institution_filter!
      @users = @users.where(tenant_id: params[:institution]) if params[:institution]
    end

    def edit_params
      params.permit(:id, :field, :email, :tenant_id)
    end

    def role_params
      params.permit(:role, :tenant_role, :publisher, :publisher_role, :funder, :funder_role, :journal_role, journal: %i[value label])
    end
  end
end
