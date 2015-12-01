require_dependency "stash_datacite/application_controller"

module StashDatacite
  class ResourceTypesController < ApplicationController
    before_action :set_resource_type, only: [:show, :edit, :update, :destroy]

    # GET /resource_types
    def index
      @resource_types = ResourceType.all
    end

    # GET /resource_types/1
    def show
    end

    # GET /resource_types/new
    def new
      @resource_type = ResourceType.new
    end

    # GET /resource_types/1/edit
    def edit
    end

    # POST /resource_types
    def create
      @resource_type = ResourceType.new(resource_type_params)

      if @resource_type.save
        redirect_to @resource_type, notice: 'Resource type was successfully created.'
      else
        render :new
      end
    end

    # PATCH/PUT /resource_types/1
    def update
      if @resource_type.update(resource_type_params)
        redirect_to @resource_type, notice: 'Resource type was successfully updated.'
      else
        render :edit
      end
    end

    # DELETE /resource_types/1
    def destroy
      @resource_type.destroy
      redirect_to resource_types_url, notice: 'Resource type was successfully destroyed.'
    end

    private
      # Use callbacks to share common setup or constraints between actions.
      def set_resource_type
        @resource_type = ResourceType.find(params[:id])
      end

      # Only allow a trusted parameter "white list" through.
      def resource_type_params
        params.require(:resource_type).permit(:resource_type, :resource_type_general, :resource_id)
      end
  end
end
