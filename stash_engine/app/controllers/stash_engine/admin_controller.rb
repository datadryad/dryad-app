require_dependency 'stash_engine/application_controller'

module StashEngine
  class AdminController < ApplicationController

    before_action :set_admin_page_info

    def index
      setup_superuser_stats
      setup_superuser_facets
      @users = User.all
      add_institution_filter!
      @sort_column = sort_column
      @users = @users.order(@sort_column.order).page(@page).per(@page_size)
    end

    private

    # this sets up the page variables for use with kaminari paging
    def set_admin_page_info
      @page = params[:page] || '1'
      @page_size = (params[:page_size].blank? || params[:page_size] != '1000000' ? '10' : '1000000')
    end

    # this sets up the sortable-table gem
    def sort_column
      institution_sort = SortableTable::SortColumnDefinition.new('tenant_id')
      name_sort = SortableTable::SortColumnCustomDefinition.new('name',
                                                                asc: 'last_name asc, first_name asc',
                                                                desc: 'last_name desc, first_name desc')
      role_sort = SortableTable::SortColumnDefinition.new('role')
      login_time_sort = SortableTable::SortColumnDefinition.new('last_login')
      sort_table = SortableTable::SortTable.new([name_sort, institution_sort, role_sort, login_time_sort])
      sort_table.sort_column(params[:sort], params[:direction])
    end

    def setup_superuser_stats
      @stats =
        {
          user_count: User.all.count,
          dataset_count: Identifier.all.count, user_7days: User.where(['created_at > ?', Time.new - 7.days]).count
        }
      setup_7_day_stats
    end

    def setup_7_day_stats
      @stats.merge!(
        dataset_started_7days: Resource.joins(:current_resource_state)
          .where(stash_engine_resource_states: { resource_state: %i[in_progress] })
          .where(['stash_engine_resources.created_at > ?', Time.new - 7.days]).count,
        dataset_submitted_7days: Identifier.where(['created_at > ?', Time.new - 7.days]).count
      )
    end

    def setup_superuser_facets
      @tenant_facets = StashEngine::Tenant.all.sort_by(&:short_name)
      @user_facets = User.all.order(last_name: :asc)
    end

    def add_institution_filter!
      return unless params[:institution]
      @users = @users.where(tenant_id: params[:institution])
    end
  end
end
