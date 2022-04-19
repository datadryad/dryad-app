require_dependency 'stash_engine/application_controller'

module StashEngine
  class AdminController < ApplicationController

    include SharedSecurityController
    helper SortableTableHelper

    before_action :require_superuser
    before_action :load_user, only: %i[popup set_role user_dashboard]
    before_action :setup_paging, only: %i[index]
    
    # the admin_users main page showing users and stats
    def index
      puts "ZZZZZ params #{params}"
      setup_stats
      setup_superuser_facets

      # Default to recently-created users
      if params[:sort].blank? && params[:q].blank?
        params[:sort] = 'created_at'
        params[:direction] = 'desc'
      end
      
      if params[:q]
        q = params[:q]
        # search the query in any searchable field
        @users = User.where(first_name: q)
                 .or(User.where(last_name: q))
                 .or(User.where(orcid: q))
                 .or(User.where(email: q))

        if q.include?(' ')
          # add any matches for "firstname lastname"
          splitname = q.split
          @users = @users.or(User.where(first_name: splitname.first, last_name: splitname.second))
        end

        @users = @users.order(helpers.sortable_table_order)
      else
        @users = User.all.order(helpers.sortable_table_order)
      end

      puts "XXXXX"
      puts "XXXXX found #{@users.size} users"
      puts "XXXXX found #{helpers.sortable_table_order} order"
      
      add_institution_filter! # if they chose a facet or are only an admin
      
      # paginate for display
      #blank_results = (@page.to_i - 1) * @page_size.to_i
      #@users = Array.new(blank_results, nil) + @users # pad out an array with empty results for earlier pages for kaminari
      #@users = Kaminari.paginate_array(@users, total_count: @users.length).page(@page).per(@page_size)
      @users = @users.page(@page).per(@page_size)
      puts "XXXXX @uses is now #{@users} -- size #{@users.size}"
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

    def add_institution_filter!
      @users = @users.where(tenant_id: params[:institution]) if params[:institution]
    end
  end
end
