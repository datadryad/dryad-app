module StashDatacite
  class DescriptionsController < ApplicationController
    before_action :set_description, only: %i[update destroy]
    before_action :ajax_require_modifiable, only: %i[update destroy]

    respond_to :json

    # GET /descriptions/new
    def new
      @description = Description.new
    end

    # POST /descriptions
    def create
      respond_to do |format|
        @desc = Description.create(resource_id: params[:resource_id], description_type: params[:type], description: params[:val])
        @desc.reload
        format.js
        format.json { render json: @desc.as_json }
      end
    end

    # PATCH/PUT /descriptions/1
    def update
      items = description_params
      unless @description&.description_type == 'technicalinfo' || items[:description].nil?
        items[:description] =
          Loofah.fragment(items[:description]).scrub!(:strip).to_s
      end
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
      ajax_blocked unless resource.id == @description.resource_id
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
