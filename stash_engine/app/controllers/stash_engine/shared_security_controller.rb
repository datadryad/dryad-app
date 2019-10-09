module StashEngine
  module SharedSecurityController

    def self.included(c)
      c.helper_method \
        %i[
          owner? admin? superuser?
        ]
    end

    def require_login
      return if current_user
      flash[:alert] = 'You must be logged in.'
      redirect_to stash_url_helpers.choose_login_path
    end

    def require_curator
      return if current_user && %w[superuser].include?(current_user.role)
      flash[:alert] = 'You must be a curator to view this information.'
      redirect_to stash_engine.dashboard_path
    end

    def ajax_require_curator
      return false unless current_user && %w[superuser].include?(current_user.role)
    end

    def require_admin
      return if current_user && %w[admin superuser].include?(current_user.role)
      flash[:alert] = 'You must be an administrator to view this information.'
      redirect_to stash_engine.dashboard_path
    end

    # this requires a method called resource in the controller that returns the current resource (usually @resource)
    def require_modify_permission
      return if current_user && resource.permission_to_edit?(user: current_user)
      display_authorization_failure
    end

    # only someone who has created the dataset in progress can edit it.  Other users can't until they're finished
    def require_in_progress_editor
      return if resource.dataset_in_progress_editor.id == current_user.id || current_user.superuser?
      display_authorization_failure
    end

    def ajax_require_current_user
      return false unless @current_user
    end

    def ajax_require_modifiable
      return if params[:id] == 'new' # a new unsaved model, not affecting the DB
      return ajax_blocked unless (current_user && resource) && resource.can_edit?(user: current_user)
    end

    # these owner/admin need to be in controller since they address the current_user from session, not easily available from model
    def owner?(resource:)
      current_user.present? && resource&.user_id == current_user.id
    end

    def admin?(resource:)
      current_user.present? && (current_user.tenant_id == resource.tenant_id && current_user.role == 'admin')
    end

    def superuser?
      current_user.present? && current_user.superuser?
    end

    def ajax_blocked
      render nothing: true, status: 403
      false
    end

  end
end
