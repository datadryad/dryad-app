require_dependency 'stash_engine/application_controller'

module StashEngine
  class MetadataEntryPagesController < ApplicationController
    before_action :require_login
    before_action :resource_exist, except: [:metadata_callback]
    before_action :require_modify_permission, except: [:metadata_callback]
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

    def resource_exist
      resource = Resource.find(params[:resource_id])
      redirect_to root_path, notice: 'The dataset you are looking for does not exist.' if resource.nil?
    end

    def duplicate_resource
      @new_res = @resource.amoeba_dup
      @new_res.current_editor_id = current_user.id
      # The default curation activity gets set to the `Resource.user_id` but we want to use the current user here
      @new_res.curation_activities.update_all(user_id: current_user.id)
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
