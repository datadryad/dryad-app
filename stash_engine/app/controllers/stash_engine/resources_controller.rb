require_dependency 'stash_engine/application_controller'

module StashEngine
  class ResourcesController < ApplicationController
    before_action :require_login, except: %i[increment_downloads data_paper]
    before_action :require_modify_permission, except: %i[index new increment_downloads data_paper]
    before_action :require_in_progress, only: %i[upload review upload_manifest]
    before_action :lockout_incompatible_uploads, only: %i[upload upload_manifest]

    attr_writer :resource

    def resource
      @resource ||= (resource_id = params[:id]) && Resource.find(resource_id)
    end
    helper_method :resource

    # GET /resources
    # GET /resources.json
    def index
      @resources = Resource.where(user_id: current_user.id)
    end

    # GET /resources/1
    # GET /resources/1.json
    def show
      respond_to do |format|
        format.xml { render template: '/stash_datacite/resources/show' }
        format.json
      end
    end

    # the show_files is for refreshing the files lists to their default states for the resource
    def show_files
      @uploads = resource.latest_file_states
      respond_to { |format| format.js }
    end

    # GET /resources/new
    def new
      create
    end

    # GET /resources/1/edit
    def edit; end

    # POST /resources
    # POST /resources.json
    def create
      resource = Resource.create(user_id: current_user.id, current_editor_id: current_user.id, tenant_id: current_user.tenant_id)
      resource.fill_blank_author!
      redirect_to metadata_entry_pages_find_or_create_path(resource_id: resource.id)
    end

    # PATCH/PUT /resources/1
    # PATCH/PUT /resources/1.json
    # rubocop:disable Metrics/AbcSize
    def update
      respond_to do |format|
        if resource.update(resource_params)
          format.html { redirect_to edit_resource_path(resource), notice: 'Resource was successfully updated.' }
          format.json { render :edit, status: :ok, location: resource }
        else
          format.html { render :edit }
          format.json { render json: resource.errors, status: :unprocessable_entity }
        end
      end
    end
    # rubocop:enable Metrics/AbcSize

    # DELETE /resources/1
    # DELETE /resources/1.json
    def destroy
      resource.destroy
      respond_to do |format|
        format.html { redirect_to return_to_path_or(dashboard_path), notice: 'The in-progress version was successfully deleted.' }
        format.json { head :no_content }
      end
    end

    # Review responds as a get request to review the resource before saving
    def review
      flash.now[:info] = [flash.now[:info]].flatten.compact.push(current_tenant.usage_disclaimer) unless current_tenant.usage_disclaimer.blank?
    end

    # Submission of the resource to the repository
    def submission; end

    # Upload files view for resource
    def upload
      # @resource.clean_uploads # might want this back cleans database to match existing files on file system
      @file = FileUpload.new(resource_id: resource.id) # this is apparantly needed for the upload control
      @uploads = resource.latest_file_states
      render 'upload_manifest' if resource.upload_type == :manifest
    end

    # upload by manifest view for resource
    def upload_manifest; end

    # PATCH/PUT /resources/1/increment_downloads
    def increment_downloads
      respond_to do |format|
        format.js do
          resource.increment_downloads
        end
      end
    end

    private

    # Never trust parameters from the scary internet, only allow the white list through.
    def resource_params
      params.require(:resource).permit(:user_id, :current_resource_state_id)
    end

    def require_in_progress
      redirect_to dashboard_path, alert: 'You may only edit the current version of the dataset' unless resource.current_state == 'in_progress'
      false
    end

    # rubocop:disable Metrics/AbcSize
    def lockout_incompatible_uploads
      if request[:action] == 'upload' && resource.upload_type == :manifest
        redirect_to upload_manifest_resource_path(resource)
        false
      elsif request[:action] == 'upload_manifest' && resource.upload_type == :files
        redirect_to upload_resource_path(resource)
        false
      end
    end
    # rubocop:enable Metrics/AbcSize
  end
end
