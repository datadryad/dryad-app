require 'kaminari'
require 'stash_engine/application_controller'

module StashEngine
  class UserAdminController < ApplicationController

    include SharedSecurityController
    helper SortableTableHelper

    before_action :require_superuser
    before_action :load_user, only: %i[email_popup role_popup tenant_popup journals_popup set_role set_tenant set_email user_profile]
    before_action :setup_paging, only: %i[index]

    # the admin_users main page showing users and stats
    def index
      setup_stats
      setup_superuser_facets
      setup_tenants

      # Default to recently-created users
      if params[:sort].blank? && params[:q].blank?
        params[:sort] = 'created_at'
        params[:direction] = 'desc'
      end

      @users = User.all

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

      ord = helpers.sortable_table_order(whitelist: %w[last_name email tenant_id role last_login])
      @users = @users.order(ord)

      add_institution_filter! # if they chose a facet or are only an admin

      # paginate for display
      @users = @users.page(@page).per(@page_size)
    end

    def role_popup
      respond_to do |format|
        format.js
      end
    end

    # sets the user role (admin/user)
    def set_role
      new_role = params[:role]
      return render(nothing: true, status: :unauthorized) if new_role == 'superuser' && current_user.role != 'superuser'

      @user.role = new_role
      @user.save!

      respond_to do |format|
        format.js
      end
    end

    def email_popup
      respond_to do |format|
        format.js
      end
    end

    # sets the user email
    def set_email
      new_email = params[:email]
      return render(nothing: true, status: :unauthorized) if current_user.role != 'superuser'

      @user.update(email: new_email)

      respond_to do |format|
        format.js
      end
    end

    def journals_popup
      respond_to do |format|
        format.js
      end
    end

    def tenant_popup
      respond_to do |format|
        format.js
      end
    end

    def set_tenant
      @user.update(tenant_id: params[:tenant])

      respond_to do |format|
        format.js
      end
    end

    def merge_popup
      selected_users = params['selected_users'].split(',')

      if selected_users.size == 2
        @user1 = StashEngine::User.find(selected_users[0])
        @user2 = StashEngine::User.find(selected_users[1])
      end

      respond_to do |format|
        format.js
      end
    end

    def merge
      user1 = StashEngine::User.find(params['user1'])
      user2 = StashEngine::User.find(params['user2'])
      user1.merge_user!(other_user: user2)
      user2.destroy

      respond_to do |format|
        format.js
      end
    end

    # profile for a user showing stats and datasets
    def user_profile
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
      @user = User.find(params[:id])
    end

    def setup_ds_status_facets
      @status_facets = @presenters.map(&:embargo_status).uniq.sort
      return unless params[:status]

      @presenters.keep_if { |i| i.embargo_status == params[:status] }
    end

    def sort_and_paginate_datasets
      @page_presenters = Kaminari.paginate_array(@presenters).page(@page).per(@page_size)
    end

    def setup_stats
      setup_superuser_stats
      @stats.each { |k, v| @stats[k] = v.count }
    end

    def setup_superuser_stats
      @stats =
        {
          user_count: User.all,
          dataset_count: Identifier.all,
          user_7days: User.where(['stash_engine_users.created_at > ?', Time.new.utc - 7.days]),
          dataset_started_7days: Resource.joins(:current_resource_state)
            .where(stash_engine_resource_states: { resource_state: %i[in_progress] })
            .where(['stash_engine_resources.created_at > ?', Time.new.utc - 7.days]),
          dataset_submitted_7days: Identifier.where(['stash_engine_identifiers.created_at > ?', Time.new.utc - 7.days])
        }
    end

    def setup_superuser_facets
      @tenant_facets = StashEngine::Tenant.all.sort_by(&:short_name)
    end

    def setup_tenants
      @tenants = [OpenStruct.new(id: '', name: '* Select Institution *')]
      @tenants << StashEngine::Tenant.all.map do |t|
        OpenStruct.new(id: t.tenant_id, name: t.short_name)
      end
      @tenants.flatten!
    end

    def add_institution_filter!
      @users = @users.where(tenant_id: params[:institution]) if params[:institution]
    end
  end
end
