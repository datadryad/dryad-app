require 'kaminari'

module StashEngine
  class UserAdminController < ApplicationController

    helper SortableTableHelper
    before_action :require_user_login
    before_action :load_user, only: %i[email_popup role_popup tenant_popup journals_popup set_role set_tenant set_email user_profile]
    before_action :setup_roles, only: %i[set_role user_profile]
    before_action :setup_paging, only: :index

    # the admin_users main page showing users and stats
    def index
      setup_superuser_facets
      setup_tenants

      # Default to recently-created users
      if params[:sort].blank? && params[:q].blank?
        params[:sort] = 'created_at'
        params[:direction] = 'desc'
      end

      @users = authorize User.all

      @users = @users.where('tenant_id = ?', params[:tenant_id]) if params[:tenant_id].present?

      if params[:q]
        q = params[:q]
        # search the query in any searchable field
        @users = @users.where('first_name LIKE ? OR last_name LIKE ? OR orcid LIKE ? or email LIKE ?',
                              "%#{q}%", "%#{q}%", "%#{q}%", "%#{q}%")
        if q.include?(' ')
          # add any matches for "firstname lastname"
          splitname = q.split
          @users = @users.or(User.where('first_name LIKE ? and last_name LIKE ?', "%#{splitname.first}%", "%#{splitname.second}%"))
        end
      end

      ord = helpers.sortable_table_order(whitelist: %w[last_name email tenant_id last_login])
      @users = @users.order(ord)

      add_institution_filter! # if they chose a facet or are only an admin

      # paginate for display
      @users = @users.page(@page).per(@page_size)
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
      save_role(role_params[:journal_role], @journal_role, StashEngine::Journal.find_by(id: role_params[:journal]))
      # set funder role
      save_role(role_params[:funder_role], @funder_role, StashEngine::Funder.find_by(id: role_params[:funder]))

      respond_to(&:js)
    end

    def email_popup
      respond_to(&:js)
    end

    # sets the user email
    def set_email
      new_email = params[:email]
      return render(nothing: true, status: :unauthorized) unless current_user.superuser?

      @user.update(email: new_email)

      respond_to(&:js)
    end

    def journals_popup
      respond_to(&:js)
    end

    def tenant_popup
      respond_to(&:js)
    end

    def set_tenant
      @user.update(tenant_id: params[:tenant])

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
      user1 = StashEngine::User.find(params['user1'])
      user2 = StashEngine::User.find(params['user2'])
      user1.merge_user!(other_user: user2)
      user2.destroy

      respond_to(&:js)
    end

    # profile for a user showing stats and datasets
    def user_profile
      @orcid_link = orcid_link
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

    def load_user
      @user = authorize User.find(params[:id]), :load_user?
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
        existing.update(role: role)
      else
        StashEngine::Role.create(user: @user, role: role, role_object: object)
      end
    end

    def setup_ds_status_facets
      @status_facets = @presenters.map(&:embargo_status).uniq.sort
      return unless params[:status]

      @presenters.keep_if { |i| i.embargo_status == params[:status] }
    end

    def sort_and_paginate_datasets
      @page_presenters = Kaminari.paginate_array(@presenters).page(@page).per(@page_size)
    end

    def setup_superuser_facets
      @tenant_facets = StashEngine::Tenant.enabled.sort_by(&:short_name)
    end

    def setup_tenants
      @tenants = [OpenStruct.new(id: '', name: '* Select institution *')]
      @tenants << StashEngine::Tenant.enabled.map do |t|
        OpenStruct.new(id: t.id, name: t.short_name)
      end
      @tenants.flatten!
    end

    def add_institution_filter!
      @users = @users.where(tenant_id: params[:institution]) if params[:institution]
    end

    def orcid_link
      return "https://sandbox.orcid.org/#{@user.orcid}" if APP_CONFIG.orcid.site == 'https://sandbox.orcid.org/'

      "https://orcid.org/#{@user.orcid}"
    end

    def role_params
      params.permit(:role, :tenant_role, :publisher, :publisher_role, :journal, :journal_role, :funder, :funder_role)
    end
  end
end
