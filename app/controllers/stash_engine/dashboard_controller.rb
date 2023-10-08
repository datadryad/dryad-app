module StashEngine
  class DashboardController < ApplicationController
    before_action :require_login, only: :show
    before_action :ensure_tenant, only: :show
    protect_from_forgery except: :user_datasets

    MAX_VALIDATION_TRIES = 5

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
          @datasets = policy_scope(Identifier, policy_scope_class: IdentifierPolicy::DashboardScope).page(@page).per(@page_size)
          @display_resources = @datasets.map { |dataset| StashDatacite::ResourcesController::DatasetPresenter.new(dataset&.latest_resource) }
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
