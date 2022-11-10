require 'stash_engine/application_controller'

module StashEngine
  class DashboardController < ApplicationController
    before_action :require_login, only: %i[show]
    before_action :ensure_tenant, only: :show

    MAX_VALIDATION_TRIES = 5

    def show; end

    def metadata_basics; end

    def preparing_to_submit; end

    def upload_basics; end

    def react_basics; end

    # an AJAX wait to allow in-progress items to complete before continuing.
    def ajax_wait
      respond_to do |format|
        format.js do
          sleep 0.1
          head :ok, content_type: 'application/javascript'
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
