require_dependency 'stash_engine/application_controller'

module StashEngine
  class ResourcesController < ApplicationController
    before_action :require_login

    before_action :set_resource, only: [:show, :edit, :update, :destroy, :review, :upload]

    before_action :require_resource_owner, except: [:index, :new]

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

    # GET /resources/new
    def new
      create
    end

    # GET /resources/1/edit
    def edit
    end

    # POST /resources
    # POST /resources.json
    def create
      @resource = Resource.create(user_id: current_user.id)
      redirect_to metadata_entry_pages_find_or_create_path(resource_id: @resource.id)
    end

    # PATCH/PUT /resources/1
    # PATCH/PUT /resources/1.json
    def update
      respond_to do |format|
        if @resource.update(resource_params)
          format.html { redirect_to edit_resource_path(@resource), notice: 'Resource was successfully updated.' }
          format.json { render :edit, status: :ok, location: @resource }
        else
          format.html { render :edit }
          format.json { render json: @resource.errors, status: :unprocessable_entity }
        end
      end
    end

    # DELETE /resources/1
    # DELETE /resources/1.json
    def destroy
      @resource.destroy
      respond_to do |format|
        if current_user.resources.present?
          format.html { redirect_to dashboard_path, notice: 'Dataset was successfully deleted.' }
          format.json { head :no_content }
        else
          format.html { redirect_to dashboard_getting_started_path }
          format.json { head :no_content }
        end
      end
    end

    # Review responds as a get request to review the resource before saving
    def review
    end

    # Submission of the resource to the repository
    def submission
    end

    # Upload files view for resource
    def upload
      #@resource.clean_uploads # might want this back cleans database to match existing files on file system
      @file = FileUpload.new(resource_id: @resource.id) #this is apparanty needed for the upload control
      @uploads = @resource.latest_file_states
    end

    private

    # Use callbacks to share common setup or constraints between actions.
    def set_resource
      @resource = Resource.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def resource_params
      params.require(:resource).permit(:user_id, :current_resource_state_id)
    end
  end
end
