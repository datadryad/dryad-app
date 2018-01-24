
module StashEngine
  module SharedSecurityController

    def self.included(c)
      c.helper_method \
        %i[
          owner? admin?
        ]
    end

    def require_login
      return if current_user
      flash[:alert] = 'You must be logged in.'
      redirect_to current_tenant.try(:omniauth_login_path)
    end

    # this requires a method called resource in the controller that returns the current resource (usually @resource)
    def require_modify_permission
      return if owner? || current_user.superuser? || admin?
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

    # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    def ajax_require_modifiable
      return if params[:id] == 'new' # a new unsaved model, not affecting the DB
      return ajax_blocked unless (current_user && resource) && # must have a current user and a resource method defined in controller
          (owner? || current_user.superuser? || admin?) && # ok permisisons for person editing
          (resource.dataset_in_progress_editor.id == current_user.id || current_user.superuser?) # must be current editor or super
    end
    # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

    def can_display_embargoed?(resource)
      !resource.private? || (current_user && current_user.id == resource.user_id)
    end

    # these owner/admin need to be in controller since they address the current_user from session, not easily available from model
    def owner?
      resource.user_id == current_user.id
    end

    def admin?
      (current_user.tenant_id == resource.tenant_id && current_user.role == 'admin')
    end

    def ajax_blocked
      render nothing: true, status: 403
      false
    end

  end
end
