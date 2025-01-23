require 'kaminari'

module StashEngine
  class UserAdminController < ApplicationController
    helper SortableTableHelper
    before_action :require_user_login
    before_action :setup_paging, only: %i[index user_profile]

    def index
      setup_facets
      setup_tenants

      # Default to recently-created users
      if params[:sort].blank? && params[:q].blank?
        params[:sort] = 'created_at'
        params[:direction] = 'desc'
      end

      @users = authorize User.all
      add_filters

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
      @users = @users.page(@page).per(@page_size)
    end

    def edit
      @user = authorize User.find(params[:id])
      setup_roles
      respond_to(&:js)
    end

    def update
      @user = authorize User.find(params[:id])
      valid = %i[email tenant_id]
      @user.roles.tenant_roles.delete_all if edit_params[:tenant_id] != @user.tenant_id
      setup_roles
      update = edit_params.slice(*valid)
      @user.update(update)
      errs = @user.errors.full_messages
      if errs.any?
        @error_message = errs[0]
        render :update_error and return
      end
      set_roles
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

    # profile for a user showing stats and datasets
    def user_profile
      @user = authorize User.find(params[:id])
      @progress_count = @user.resources.in_progress.distinct.count
      # some of these columns are calculated values for display that aren't stored (publication date)
      @resources = @user.resources.latest_per_dataset.distinct.joins(:last_curation_activity)
        .select('stash_engine_resources.*, stash_engine_curation_activities.status')
      ord = helpers.sortable_table_order(whitelist: %w[title status publication_date total_file_size updated_at current_editor_id])
      add_profile_filters
      @resources = @resources.includes(%i[identifier current_resource_state last_curation_activity editor])
      @resources = @resources.order(ord).page(@page).per(@page_size)
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

    def setup_roles
      @system_role = @user.roles.system_roles&.first
      @tenant_role = @user.roles.tenant_roles&.first
      @journal_role = @user.roles.journal_roles&.first
      @publisher_role = @user.roles.journal_org_roles&.first
      @funder_role = @user.roles.funder_roles&.first
    end

    # sets the user roles
    def set_roles
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
      @user.reload
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

    def setup_facets
      @tenant_facets = StashEngine::Tenant.enabled.sort_by(&:short_name)
    end

    def setup_tenants
      @tenants = [OpenStruct.new(id: '', name: '')]
      @tenants << StashEngine::Tenant.all.sort_by(&:short_name).map do |t|
        OpenStruct.new(id: t.id, name: t.short_name)
      end
      @tenants.flatten!
    end

    def add_filters
      @users = @users.joins(:roles).where(roles: { role: params[:role_filter] }).distinct if params[:role_filter].present?
      @users = @users.where(tenant_id: params[:tenant_filter]) if params[:tenant_filter].present?
    end

    def add_profile_filters
      @status_facets = @resources.map(&:status).uniq.sort
      return unless profile_params[:status]

      @resources = @resources.where('stash_engine_curation_activities.status': profile_params[:status])
    end

    def edit_params
      params.permit(:id, :field, :email, :tenant_id)
    end

    def role_params
      params.permit(:role, :tenant_role, :publisher, :publisher_role, :funder, :funder_role, :journal_role, journal: %i[value label])
    end

    def profile_params
      params.permit(:status)
    end
  end
end
