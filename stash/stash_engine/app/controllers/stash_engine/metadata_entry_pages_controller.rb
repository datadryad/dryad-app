require_dependency 'stash_engine/application_controller'

module StashEngine
  class MetadataEntryPagesController < ApplicationController
    before_action :require_login, except: %i[edit_by_doi]
    before_action :resource_exist, except: %i[metadata_callback]
    before_action :require_modify_permission, except: %i[metadata_callback edit_by_doi]
    before_action :require_in_progress_editor, only: %i[find_or_create]
    before_action :require_can_duplicate, only: :new_version
    before_action :ajax_require_modifiable, only: %i[reject_agreement accept_agreement]

    def resource
      @resource ||= Resource.find(params[:resource_id])
    end
    helper_method :resource

    # GET/POST/PUT  /generals/find_or_create
    def find_or_create
      return unless @resource.submitted? # create a new version if this is a submitted version

      redirect_to(metadata_entry_pages_new_version_path(resource_id: params[:resource_id]))
    end

    # rubocop:disable Metrics/AbcSize
    # GET /stash/edit/{doi}/{edit_code}
    def edit_by_doi
      redirect_to root_path, alert: 'The target dataset is being processed. Please try again later.' and return if resource.processing?

      # if this call was made with a returnURL, save it that URL in the session for the end of the submission process
      session[:returnURL] = params[:returnURL] if params[:returnURL]

      # check if edit_code is present, and if so, store in the session
      valid_edit_code?

      if ownership_transfer_needed?
        if current_user
          @resource.user_id = current_user.id
          @resource.save
        else
          # The user will need to login (possibly creating an
          # account), and then they will be redirected back to this
          # method to receive ownership of the dataset
          flash[:alert] = 'You must be logged in.'
          session[:target_page] = request.fullpath
          redirect_to stash_url_helpers.choose_login_path and return
        end
      end

      # If the user is logged in, they will remain logged in, just with the added benefit
      # that they have access to edit this dataset. But if they were not logged in,
      # log them in as the dataset owner, and ensure the tenant_id is set correctly.
      unless current_user
        session[:user_id] = resource.user_id
        redirect_to choose_sso_path and return if current_user.tenant_id.blank?
      end

      redirect_to(metadata_entry_pages_find_or_create_path(resource_id: resource.id))
    end
    # rubocop:enable Metrics/AbcSize

    # create a new version of this resource before editing with find or create
    def new_version
      duplicate_resource

      # redirect to find or create path
      redirect_to metadata_entry_pages_find_or_create_path(resource_id: @new_res.id)
    end

    def reject_agreement
      respond_to do |format|
        format.js do
          resource.destroy if resource.title.nil? && resource.descriptions.first.description.nil?
        end
      end
    end

    def accept_agreement
      respond_to do |format|
        format.json do
          resource.update(accepted_agreement: true)
          render json: resource
        end
      end
    end

    private

    def ownership_transfer_needed?
      valid_edit_code? && (resource.user_id == 0)
    end

    def resource_exist
      resource = Resource.find(params[:resource_id]) if params[:resource_id]
      resource = resource_from_doi if resource.nil?
      redirect_to root_path, alert: 'The dataset you are looking for does not exist.' if resource.nil?
    end

    def resource_from_doi
      doi = params[:doi]
      doi&.match(/doi:(.*)/) do |m|
        doi = m[1]
      end
      id = Identifier.where(identifier: doi).first
      @resource = id&.latest_resource
      params[:resource_id] = @resource&.id
      @resource
    end

    def duplicate_resource
      @new_res = @resource.amoeba_dup
      @new_res.current_editor_id = current_user&.id
      # The default curation activity gets set to the `Resource.user_id` but we want to use the current user here
      @new_res.curation_activities.update_all(user_id: current_user&.id)
      @new_res.save!
    end

    def require_can_duplicate
      return false unless (@identifier = resource.identifier)

      set_return_to_path_from_referrer # needed for dropping into edit (and back) from various places in the ui

      if @identifier.in_progress_only?
        redirect_to(metadata_entry_pages_find_or_create_path(resource_id: @identifier.in_progress_resource.id))
        false
      elsif @identifier.processing? || @identifier.error?
        redirect_to dashboard_path, alert: 'You may not create a new version of the dataset until processing completes or any errors are resolved'
        false
      end
    end

  end
end
