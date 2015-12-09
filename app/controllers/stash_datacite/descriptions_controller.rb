require_dependency 'stash_datacite/application_controller'

module StashDatacite
  class DescriptionsController < ApplicationController
    before_action :set_description, only: [:update, :destroy]

    respond_to :json

    # GET /descriptions/new
    def new
      @description = Description.new
    end

    # PATCH/PUT /descriptions/1
    def update
      respond_to do |format|
        if @description.update(description_params)
          format.js { render template: 'stash_datacite/shared/update.js.erb' }
        else
          format.html { render :edit }
        end
      end
    end

    # DELETE /descriptions/1
    def destroy
      @description.destroy
      redirect_to descriptions_url, notice: 'Description was successfully destroyed.'
    end

    private

    # Use callbacks to share common setup or constraints between actions.
    def set_description
      @description = Description.find(description_params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def description_params
      params.require(:description).permit(:id, :description, :description_type, :resource_id)
    end
  end
end
