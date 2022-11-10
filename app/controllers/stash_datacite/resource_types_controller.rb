require 'stash_datacite/application_controller'

module StashDatacite
  class ResourceTypesController < ApplicationController
    before_action :set_resource_type, only: %i[update destroy]

    # GET /resource_types/new
    def new
      @resource_type = ResourceType.new
    end

    # POST /resource_types
    def create
      @resource_type = ResourceType.new(resource_type_params)
      respond_to do |format|
        if @resource_type.save
          format.js
        else
          format.html { render :new }
        end
      end
    end

    # PATCH/PUT /resource_types/1
    def update
      respond_to do |format|
        if @resource_type.update(resource_type_params)
          # @resource_type.resource_type = @resource_type.resource_type_general
          # not overwriting any existing resource_type values
          @resource_type.save
          format.js { render template: 'stash_datacite/shared/update.js.erb' }
        else
          format.html { render :edit }
        end
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
      @resource_type = ResourceType.find(resource_type_params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def resource_type_params
      params.require(:resource_type).permit(:id, :resource_type_general, :resource_type, :resource_id)
    end
  end
end
