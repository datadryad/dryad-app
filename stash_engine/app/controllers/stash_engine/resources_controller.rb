require_dependency 'stash_engine/application_controller'

module StashEngine
  class ResourcesController < ApplicationController
    before_action :require_login, except: %i[increment_downloads data_paper]
    before_action :require_resource_owner, except: %i[index new increment_downloads data_paper]

    attr_writer :resource

    def resource
      @resource ||= (resource_id = params[:id]) && Resource.find(resource_id)
    end
    helper_method :resource

    # GET /resources
    # GET /resources.json
    def index
      @resources = Resource.where(user_id: current_user.id)
      @titles = metadata_engine::Title.all
    end

    # GET /resources/1
    # GET /resources/1.json
    def show
      respond_to do |format|
        format.xml { render template: '/stash_datacite/resources/show' }
        format.json {}
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
      resource = Resource.create(user_id: current_user.id)
      redirect_to metadata_entry_pages_find_or_create_path(resource_id: resource.id)
    end

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
        if current_user.resources.present?
          format.html { redirect_to dashboard_path, notice: 'Dataset was successfully deleted.' }
        else
          format.html { redirect_to dashboard_getting_started_path }
        end
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
      @file = FileUpload.new(resource_id: resource.id) # this is apparanty needed for the upload control
      @uploads = resource.latest_file_states
      render 'upload_manifest' if resource.upload_type == :manifest
    end

    # upload by manifest view for resource
    def upload_manifest
      (redirect_to upload_resource_path(resource) && return) if resource.upload_type == :files
    end

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

    def require_resource_owner
      resource_user_id = resource.user_id
      current_user_id = current_user.id
      return if resource_user_id == current_user_id

      Rails.logger.warn("Resource #{resource ? resource.id : 'nil'}: user ID is #{resource_user_id || 'nil'} but " \
                    "current user is #{current_user_id || 'nil'}")
      flash[:alert] = 'You do not have permission to modify this dataset.'
      redirect_to stash_engine.dashboard_path
    end

  end
end
