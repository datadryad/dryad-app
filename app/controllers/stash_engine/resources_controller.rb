require_dependency 'stash_engine/application_controller'

module StashEngine
  class ResourcesController < ApplicationController
    before_action :require_login, except: [:increment_downloads, :data_paper, :stream_download]

    before_action :set_resource, only: [:show, :edit, :update, :destroy, :review, :upload, :increment_downloads]

    before_action :require_resource_owner, except: [:index, :new, :increment_downloads, :data_paper, :stream_download]

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

    # allows streaming of file through the dash UI without exposing Merritt URL
    # this is just for testing right now.
    #
    # TODO: It looks like merritt is redirecting me to the guest login when I try to stream.
    # Code 302 found, http://merritt-dev.cdlib.org/guest_login
    #
    # try sending the tenant repository username/password as as a basic-auth header.
    # that should get you the cookie and another redirect.
    # ideally your client library would then send the cookie when it follows the redirect,
    # but I know we had problems with that in stash-sword (didn't work till we upgraded to RestClient 2.0)
    # so you might need to do that by hand if you're not using RestClient.
    def stream_download
      #stream_response('http://www.cdlib.org/images/staff/sdeng.jpg', current_tenant.repository.username,
      #       current_tenant.repository.password)
      #stream_response('http://merritt-dev.cdlib.org/d/ark%3A%2Fb5072%2Ffk2pv6hw34', current_tenant.repository.username,
      #                current_tenant.repository.password) # testing resource_id 747 on dev

      stream_response('http://merritt-dev.cdlib.org/u/ark%3A%2Fb5072%2Ffk2pv6hw34', current_tenant.repository.username,
                      current_tenant.repository.password) # testing resource_id 747 on dev


    end

    # Upload files view for resource
    def upload
      #@resource.clean_uploads # might want this back cleans database to match existing files on file system
      @file = FileUpload.new(resource_id: @resource.id) #this is apparanty needed for the upload control
      @uploads = @resource.latest_file_states
    end

    # PATCH/PUT /resources/1/increment_downloads
    def increment_downloads
      respond_to do |format|
        format.js do
          @resource.increment_downloads
        end
      end
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
