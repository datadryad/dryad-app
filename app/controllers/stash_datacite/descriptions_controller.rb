module StashDatacite
  class DescriptionsController < ApplicationController
    before_action :set_description, only: %i[update destroy]
    before_action :ajax_require_modifiable, only: %i[update destroy]

    respond_to :json

    # GET /descriptions/new
    def new
      @description = Description.new
    end

    # PATCH/PUT /descriptions/1
    def update
      items = description_params
      items[:description] = Loofah.fragment(items[:description]).scrub!(:strip).to_s
      respond_to do |format|
        if @description.update(items)
          format.json { render json: @description.slice(:id, :resource_id, :description, :description_type) }
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
      return ajax_blocked unless resource.id == @description.resource_id
    end

    def resource
      @resource ||= (params[:description] ? StashEngine::Resource.find(description_params[:resource_id]) : @description.resource)
    end

    # Only allow a trusted parameter "white list" through.
    def description_params
      params.require(:description).permit(:id, :description, :description_type, :resource_id)
    end
  end
end
