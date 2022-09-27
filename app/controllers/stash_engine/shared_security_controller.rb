# rubocop:disable Metrics/ModuleLength
module StashEngine
  module SharedSecurityController

    def self.included(c)
      c.helper_method \
        %i[
          owner? admin? curator? limited_curator? superuser?
        ]
    end

    def require_login_wo_tenant
      return if current_user.present?

      flash[:alert] = 'You must be logged in.'
      redirect_to stash_url_helpers.choose_login_path
    end

    def require_login
      if current_user.present? && current_user.tenant_id.present?
        target_page = session[:target_page]
        if target_page.present?
          # This session had originally been navigating to a specific target_page and was redirected
          # to the login page. Now that they are logged in, we will redirect to the target_page,
          # but first clear it from the session so we don't continually redirect to it.
          session[:target_page] = nil
          redirect_to target_page
        end
        return
      end

      return if valid_edit_code?

      flash[:alert] = 'You must be logged in.'
      session[:target_page] = request.fullpath
      redirect_to stash_url_helpers.choose_login_path
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
      redirect_to stash_url_helpers.dashboard_path
    end

    def require_superuser
      return if current_user && current_user.superuser?

      flash[:alert] = 'You must be a superuser to view this information.'
      redirect_to stash_url_helpers.dashboard_path
    end

    def require_curator
      return if current_user && current_user.curator?

      flash[:alert] = 'You must be a curator to view this information.'
      redirect_to stash_url_helpers.dashboard_path
    end

    def ajax_require_curator
      return false unless current_user && current_user.curator?
    end

    def require_limited_curator
      return if current_user && current_user.limited_curator?

      flash[:alert] = 'You must be a curator to view this information.'
      redirect_to stash_url_helpers.dashboard_path
    end

    def ajax_require_limited_curator
      return false unless current_user && current_user.limited_curator?
    end

    def require_admin
      return if current_user && (current_user.limited_curator? || current_user.role == 'admin' ||
                                 current_user.journals_as_admin.present? ||
                                 current_user.funders_as_admin.present?)

      flash[:alert] = 'You must be an administrator to view this information.'
      redirect_to stash_url_helpers.dashboard_path
    end

    # this requires a method called resource in the controller that returns the current resource (usually @resource)
    def require_modify_permission
      return if valid_edit_code?
      return if current_user && resource.permission_to_edit?(user: current_user)

      display_authorization_failure
    end

    # only someone who has created the dataset in progress can edit it.  Other users can't until they're finished
    def require_in_progress_editor
      return if valid_edit_code? ||
                resource&.dataset_in_progress_editor&.id == current_user.id ||
                current_user.curator?

      display_authorization_failure
    end

    def ajax_require_current_user
      return false unless @current_user
    end

    def ajax_require_modifiable
      return if params[:id] == 'new' # a new unsaved model, not affecting the DB
      return ajax_blocked unless valid_edit_code? ||
                                 ((current_user && resource) && resource.can_edit?(user: current_user))
    end

    # these owner/admin need to be in controller since they address the current_user from session, not easily available from model
    def owner?(resource:)
      current_user.present? && resource&.user_id == current_user.id
    end

    def admin?(resource:)
      resource&.admin_for_this_item?(user: current_user)
    end

    def curator?
      current_user.present? && current_user.curator?
    end

    def limited_curator?
      current_user.present? && current_user.limited_curator?
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
# rubocop:enable Metrics/ModuleLength
