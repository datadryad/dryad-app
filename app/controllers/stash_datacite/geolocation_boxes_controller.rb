require_dependency 'stash_datacite/application_controller'

module StashDatacite
  class GeolocationBoxesController < ApplicationController
    before_action :set_geolocation_box, only: [:show, :edit, :update, :delete]

    # # GET /geolocation_boxes/
    def boxes_coordinates
      @geolocation_boxes = GeolocationBox.select(:resource_id, :sw_latitude, :sw_longitude, :ne_latitude, :ne_longitude).
                             from_resource_id(params[:resource_id])
      respond_to do |format|
        format.html
        format.json { render json: @geolocation_boxes }
      end
    end

    # # GET /geolocation_boxes/1/edit
    # def edit
    # end

    # POST /geolocation_boxes
    def map_coordinates
      p = params.except(:controller, :action)
      Geolocation.new_geolocation(box: [p[:ne_latitude], p[:ne_longitude], p[:sw_latitude], p[:sw_longitude]],
                                  resource_id: params[:resource_id])
      respond_to do |format|
        @resource = StashDatacite.resource_class.find(params[:resource_id])
        @geolocation_boxes = GeolocationBox.from_resource_id(params[:resource_id])
        format.js { render template: 'stash_datacite/geolocation_boxes/create.js.erb' }
        end
      end
    end

    # POST /geolocation_boxes
    def create
      @geolocation_box = GeolocationBox.create(ne_latitude: params[:ne_latitude], ne_longitude: params[:ne_longitude],
                                               sw_latitude: params[:sw_latitude], sw_longitude: params[:sw_longitude])
      @geolocation = Geolocation.create(box_id: @geolocation_box.id, resource_id: params[:resource_id])
      respond_to do |format|
        @resource = StashDatacite.resource_class.find(params[:resource_id])
        @geolocation_boxes = GeolocationBox.from_resource_id(params[:resource_id])
        format.js
      end
    end

    # DELETE /geolocation_boxes/1
    def delete
      @sw_latitude = @geolocation_box.sw_latitude
      @sw_longitude = @geolocation_box.sw_longitude
      @ne_latitude = @geolocation_box.ne_latitude
      @ne_longitude = @geolocation_box.ne_longitude
      @geolocation_box.try(:geolocation).try(:destroy_box)

      @resource = StashDatacite.resource_class.find(params[:resource_id])
      @geolocation_boxes = GeolocationBox.from_resource_id(params[:resource_id])
      respond_to do |format|
        format.js
      end
    end

    private

    # Use callbacks to share common setup or constraints between actions.
    def set_geolocation_box
      @geolocation_box = GeolocationBox.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def geolocation_box_params
      params.require(:geolocation_box).permit(:sw_latitude, :sw_longitude, :ne_latitude,
                                              :ne_longitude, :resource_id)
    end
  end
end
