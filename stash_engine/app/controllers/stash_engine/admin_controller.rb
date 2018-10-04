require_dependency 'stash_engine/application_controller'

# TODO: maybe should move this around and move the index into a user's controller since it's mostly (but not all) about users.
module StashEngine
  class AdminController < ApplicationController # rubocop:disable Metrics/ClassLength
    include SharedSecurityController

    before_action :load_user, only: %i[popup set_role user_dashboard]
    before_action :require_admin
    before_action :set_admin_page_info, only: %i[index user_dashboard]

    # the admin main page showing users and stats
    def index
      setup_stats
      setup_superuser_facets
      @users = User.all
      add_institution_filter! # if they chose a facet or are only an admin
      @sort_column = user_sort_column
      @users = @users.order(@sort_column.order).page(@page).per(@page_size)
    end

    # popup a dialog with the user's admin info for changing
    def popup
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

    # dashboard for a user showing stats and datasets
    def user_dashboard
      @progress_count = Resource.in_progress.where(user_id: @user.id).count
      # some of these columns are calculated values for display that aren't stored (publication date)
      @resources = Resource.where(user_id: @user.id).latest_per_dataset
      @presenters = @resources.map { |res| StashDatacite::ResourcesController::DatasetPresenter.new(res) }
      setup_ds_status_facets
      sort_and_paginate_datasets
    end

    private

    # this sets up the page variables for use with kaminari paging
    def set_admin_page_info
      @page = params[:page] || '1'
      @page_size = (params[:page_size].blank? || params[:page_size] != '1000000' ? '10' : '1000000')
    end

    def load_user
      @user = User.find(params[:id])
    end

    # this sets up the sortable-table gem for users table
    def user_sort_column
      institution_sort = SortableTable::SortColumnDefinition.new('tenant_id')
      name_sort = SortableTable::SortColumnCustomDefinition.new('name',
                                                                asc: 'last_name asc, first_name asc',
                                                                desc: 'last_name desc, first_name desc')
      role_sort = SortableTable::SortColumnDefinition.new('role')
      login_time_sort = SortableTable::SortColumnDefinition.new('last_login')
      sort_table = SortableTable::SortTable.new([name_sort, institution_sort, role_sort, login_time_sort])
      sort_table.sort_column(params[:sort], params[:direction])
    end

    def dataset_sort_column
      title = SortableTable::SortColumnDefinition.new('title')
      status = SortableTable::SortColumnDefinition.new('embargo_status')
      pub_date = SortableTable::SortColumnDefinition.new('publication_date')
      updated_at = SortableTable::SortColumnDefinition.new('updated_at')
      size = SortableTable::SortColumnDefinition.new('size')
      edited_by = SortableTable::SortColumnDefinition.new('edited_by_name')
      sort_table = SortableTable::SortTable.new([title, status, pub_date, updated_at, size, edited_by])
      sort_table.sort_column(params[:sort], params[:direction])
    end

    def setup_ds_status_facets
      @status_facets = @presenters.map(&:embargo_status).uniq.sort
      return unless params[:status]
      @presenters.keep_if { |i| i.embargo_status == params[:status] }
    end

    def sort_and_paginate_datasets
      @sort_column = dataset_sort_column
      manual_sort!(@presenters, @sort_column)
      @page_presenters = Kaminari.paginate_array(@presenters).page(@page).per(@page_size)
    end

    def setup_stats
      setup_superuser_stats
      limit_to_tenant! if current_user.role == 'admin'
      @stats.each { |k, v| @stats[k] = v.count }
    end

    # TODO: move into models or elsewhere for queries, but can't get tests to run right now so holding off
    def setup_superuser_stats
      @stats =
        {
          user_count: User.all,
          dataset_count: Identifier.all,
          user_7days: User.where(['stash_engine_users.created_at > ?', Time.new - 7.days]),
          dataset_started_7days: Resource.joins(:current_resource_state)
            .where(stash_engine_resource_states: { resource_state: %i[in_progress] })
            .where(['stash_engine_resources.created_at > ?', Time.new - 7.days]),
          dataset_submitted_7days: Identifier.where(['stash_engine_identifiers.created_at > ?', Time.new - 7.days])
        }
    end

    # TODO: move into models or elsewhere for queries, but can't get tests to run right now so holding off
    def limit_to_tenant! # rubocop:disable Metrics/AbcSize
      @stats[:user_count] = @stats[:user_count].where(tenant_id: current_user.tenant_id)
      @stats[:dataset_count] = @stats[:dataset_count].joins(resources: :user)
        .where(['stash_engine_users.tenant_id = ?', current_user.tenant_id]).distinct
      @stats[:user_7days] = @stats[:user_7days].where(tenant_id: current_user.tenant_id)
      @stats[:dataset_started_7days] = @stats[:dataset_started_7days].joins(:user)
        .where(['stash_engine_users.tenant_id = ?', current_user.tenant_id])
      @stats[:dataset_submitted_7days] = @stats[:dataset_submitted_7days].joins(resources: :user)
        .where(['stash_engine_users.tenant_id = ?', current_user.tenant_id]).distinct
    end

    def setup_superuser_facets
      @tenant_facets = StashEngine::Tenant.all.sort_by(&:short_name)
    end

    def add_institution_filter!
      if current_user.role == 'admin'
        @users = @users.where(tenant_id: current_user.tenant_id)
      elsif params[:institution]
        @users = @users.where(tenant_id: params[:institution])
      end
    end
  end
end
