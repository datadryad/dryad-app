require_dependency 'stash_engine/application_controller'

module StashEngine
  class MetadataEntryPagesController < ApplicationController
    before_action :require_login
    before_action :resource_exist, except: [:metadata_callback]
    before_action :require_modify_permission, except: [:metadata_callback]
    before_action :require_in_progress_editor, only: %i[find_or_create]

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
      set_return_to_path_from_referrer # needed for dropping into edit (and back) from various places in the ui
      # create new version deep copy of most items
      @resource = Resource.find(params[:resource_id])
      identifier = @resource.identifier
      in_progress_resource = identifier && identifier.in_progress_resource
      if in_progress_resource
        redirect_to(metadata_entry_pages_find_or_create_path(resource_id: in_progress_resource.id)) && return
      end
      duplicate_resource

      # redirect to find or create path
      redirect_to metadata_entry_pages_find_or_create_path(resource_id: @new_res.id)
    end

    private

    def resource_exist
      resource = Resource.find(params[:resource_id])
      redirect_to root_path, notice: 'The dataset you are looking for does not exist.' if resource.nil?
    end

    def duplicate_resource
      @new_res = @resource.amoeba_dup
      @new_res.current_editor_id = current_user.id
      @new_res.save!
    end

  end
end
