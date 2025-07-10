# rubocop:disable Metrics/ModuleLength, Metrics/AbcSize
module StashEngine
  module SharedSecurityController

    def self.included(c)
      c.helper_method \
        %i[
          owner? admin? min_curator? min_app_admin? superuser?
        ]
    end

    def require_user_login
      return nil if current_user.present?

      flash[:alert] = 'You must be logged in.'
      redirect_to stash_url_helpers.choose_login_path and return
    end

    def require_login
      require_user_login

      unless current_user.tenant_id.present?
        flash[:alert] = 'You must select an institution (or Continue).'
        redirect_to stash_url_helpers.choose_sso_path and return
      end

      if %w[email shibboleth].include?(current_user.tenant.authentication&.strategy) &&
        (current_user.tenant_auth_date.blank? || current_user.tenant_auth_date.before?(1.month.ago))
        redirect_to stash_url_helpers.choose_sso_path(reverify: true) and return
      end

      unless current_user.validated?
        flash[:alert] = 'Please validate your email address'
        redirect_to stash_url_helpers.email_validate_path and return
      end

      target_page = session[:target_page]
      if target_page.present?
        # This session had originally been navigating to a specific target_page and was redirected
        # to the login page. Now that they are logged in, we will redirect to the target_page,
        # but first clear it from the session so we don't continually redirect to it.
        session[:target_page] = nil
        redirect_to target_page and return
      end

      nil
    end

    def bust_cache
      response.headers['Cache-Control'] = 'no-cache, no-store'
      response.headers['Pragma'] = 'no-cache'
      response.headers['Expires'] = 'Mon, 01 Jan 1990 00:00:00 GMT'
    end

    # requires @resource to be set and not editing a version that is obsolete
    def require_not_obsolete
      return if @resource&.current_resource_state&.resource_state == 'in_progress'

      flash[:alert] = 'You may not edit a submitted version of your dataset by using the back button. Please open your dataset from the editing link'
      redirect_to stash_url_helpers.choose_dashboard_path
    end

    def require_superuser
      return if current_user && current_user.superuser?

      flash[:alert] = 'You must be a superuser to view this information.'
      redirect_to stash_url_helpers.choose_dashboard_path
    end

    def require_curator
      return if current_user && current_user.min_curator?

      flash[:alert] = 'You must be a curator to view this information.'
      redirect_to stash_url_helpers.choose_dashboard_path
    end

    def ajax_require_curator
      false unless current_user && current_user.min_curator?
    end

    def require_min_app_admin
      return if current_user && current_user.min_app_admin?

      flash[:alert] = 'You must be a curator to view this information.'
      redirect_to stash_url_helpers.choose_dashboard_path
    end

    def ajax_require_min_app_admin
      false unless current_user && current_user.min_app_admin?
    end

    def require_admin
      return if current_user && current_user.min_admin?

      flash[:alert] = 'You must be an administrator to view this information.'
      redirect_to stash_url_helpers.choose_dashboard_path
    end

    # this requires a method called resource in the controller that returns the current resource (usually @resource)
    def require_modify_permission
      return if valid_edit_code?
      return if current_user.present? && resource.editor.present? && current_user == resource.editor
      return if current_user.present? && resource.editor.nil? && resource.permission_to_edit?(user: current_user)

      display_authorization_failure
    end

    def require_duplicate_permission
      return if valid_edit_code?
      return if current_user.present? && resource.permission_to_edit?(user: current_user)

      display_authorization_failure
    end

    # only someone who has created the dataset in progress can edit it.  Other users can't until they're finished
    def require_in_progress_editor
      return if valid_edit_code? ||
                resource&.dataset_in_progress_editor&.id == current_user.id ||
                current_user.min_curator?

      display_authorization_failure
    end

    def ajax_require_current_user
      false unless @current_user
    end

    def ajax_require_modifiable
      return if params[:id] == 'new' # a new unsaved model, not affecting the DB

      ajax_blocked unless valid_edit_code? ||
                                 ((current_user && resource) && resource.can_edit?(user: current_user))
    end

    # these owner/admin need to be in controller since they address the current_user from session, not easily available from model
    def owner?(resource:)
      current_user.present? && resource&.users&.include?(current_user)
    end

    def admin?(resource:)
      resource&.admin_for_this_item?(user: current_user)
    end

    def min_curator?
      current_user.present? && current_user.min_curator?
    end

    def min_app_admin?
      current_user.present? && current_user.min_app_admin?
    end

    def superuser?
      current_user.present? && current_user.superuser?
    end

    def ajax_blocked
      render body: '', status: 403, content_type: request.content_type.to_s
      false
    end

    def valid_edit_code?
      edit_code = params[:edit_code] || session[:edit_code]
      if defined?(resource) && resource.present? && (edit_code == resource&.identifier&.edit_code)
        # Code is valid, so save it in the session for later use (and implicitly return true)
        session[:edit_code] = edit_code
      else
        false
      end
    end

  end
end
# rubocop:enable Metrics/ModuleLength, Metrics/AbcSize
