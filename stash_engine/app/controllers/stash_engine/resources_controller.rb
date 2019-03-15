require_dependency 'stash_engine/application_controller'

module StashEngine
  class ResourcesController < ApplicationController
    before_action :require_login, except: %i[data_paper]
    before_action :require_modify_permission, except: %i[index new data_paper]
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
    # rubocop:disable Metrics/AbcSize
    def create
      resource = Resource.new(user_id: current_user.id, current_editor_id: current_user.id, tenant_id: current_user.tenant_id)
      my_id = Stash::Doi::IdGen.mint_id(resource: resource)
      id_type, id_text = my_id.split(':', 2)
      db_id_obj = Identifier.create(identifier: id_text, identifier_type: id_type.upcase)
      resource.identifier_id = db_id_obj.id
      resource.save
      resource.fill_blank_author!
      redirect_to metadata_entry_pages_find_or_create_path(resource_id: resource.id)
    rescue StandardError
      redirect_to dashboard_path, alert: 'Unable to register a DOI at this time. Please contact help@datadryad.org for assistance.'
    end
    # rubocop:enable Metrics/AbcSize

    # PATCH/PUT /resources/1
    # PATCH/PUT /resources/1.json
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
    def review; end

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

    private

    # Never trust parameters from the scary internet, only allow the white list through.
    def resource_params
      params.require(:resource).permit(:user_id, :current_resource_state_id)
    end

    def require_in_progress
      redirect_to dashboard_path, alert: 'You may only edit the current version of the dataset' unless resource.current_state == 'in_progress'
      false
    end

    def lockout_incompatible_uploads
      if request[:action] == 'upload' && resource.upload_type == :manifest
        redirect_to upload_manifest_resource_path(resource)
        false
      elsif request[:action] == 'upload_manifest' && resource.upload_type == :files
        redirect_to upload_resource_path(resource)
        false
      end
    end

  end
end
