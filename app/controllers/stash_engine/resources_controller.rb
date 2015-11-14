require_dependency "stash_engine/application_controller"

module StashEngine
  class ResourcesController < ApplicationController
    before_action :set_resource, only: [:show, :edit, :update, :destroy]

    # GET /resources
    # GET /resources.json
    def index
      @resources = Resource.all
      @titles = StashDatacite::Title.all
    end

    # GET /resources/1
    # GET /resources/1.json
    def show
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
      @resource = Resource.new
      @resource.save!
      redirect_to stash_datacite.generals_new_path(resource_id: @resource.id)
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
        format.html { redirect_to resources_url, notice: 'Resource was successfully destroyed.' }
        format.json { head :no_content }
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

