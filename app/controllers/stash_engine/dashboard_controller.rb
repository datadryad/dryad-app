module StashEngine
  class DashboardController < ApplicationController
    before_action :require_login, only: %i[show user_datasets]
    before_action :ensure_tenant, only: %i[show user_datasets]
    protect_from_forgery except: :user_datasets

    MAX_VALIDATION_TRIES = 5

    def choose
      return redirect_to admin_dashboard_path if current_user&.min_admin?

      redirect_to dashboard_path
    end

    def show
      @doi = CGI.escape(params[:doi] || '')
    end

    def metadata_basics; end

    def preparing_to_submit; end

    def upload_basics; end

    def react_basics; end

    def user_datasets
      @page = params[:page] || '1'
      @page_size = params[:page_size] || '10'
      respond_to do |format|
        format.js do
          @datasets = current_user.resources.latest_per_dataset.distinct
            .joins(:last_curation_activity)
            .select("stash_engine_resources.*,
            CASE
              WHEN status='action_required' THEN 0
              WHEN (status='in_progress' and (current_editor_id = #{current_user.id} or  current_editor_id is null)) THEN 0
              WHEN (status='in_progress' and current_editor_id in (#{StashEngine::User.min_curators.map(&:id).join(',')})) THEN 3
              WHEN status='in_progress' THEN 1
              WHEN status='peer_review' THEN 2
              WHEN status in ('submitted', 'curation', 'processing') THEN 3
              WHEN status='withdrawn' THEN 5
              ELSE 4
            END as sort_order")
            .order('sort_order asc, stash_engine_resources.updated_at desc').page(@page).per(@page_size)
          @datasets = @datasets.preload(%i[last_curation_activity stash_version current_resource_state identifier])
            .includes(identifier: :resources)
        end
      end
    end

    # methods below are private
    private

    # some people seem to get to the dashboard without having their tenant set.
    def ensure_tenant
      return unless current_user && current_user.tenant_id.blank?

      redirect_to choose_sso_path, alert: 'You must choose if you are associated with an institution before continuing'
    end

    def create_missing_email_address
      current_user.update(email: current_user.old_dryad_email) if current_user.email.blank? && !current_user.old_dryad_email.blank?
    end

  end
end
