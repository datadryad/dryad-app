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
      geo = geolocation_by_box(params)
      unless geo
        box_params = params[:geolocation_box]
        geo = Geolocation.new_geolocation(box: [params[:ne_latitude], params[:ne_longitude],
                                          params[:sw_latitude], params[:sw_longitude]],
                                    resource_id: params[:resource_id])
      end
      respond_to do |format|
        @resource = StashDatacite.resource_class.find(params[:resource_id])
        @geolocation_boxes = GeolocationBox.from_resource_id(params[:resource_id])
        @geolocation_box = geo.geolocation_box
        format.js { render template: 'stash_datacite/geolocation_boxes/create.js.erb' }
      end
    end

    # POST /geolocation_boxes
    def create
      geo = geolocation_by_box(params[:geolocation_box])
      unless geo
        box_params = params[:geolocation_box]
        geo = Geolocation.new_geolocation(box: [box_params[:ne_latitude], box_params[:ne_longitude],
                                          box_params[:sw_latitude], box_params[:sw_longitude]],
                                    resource_id: params[:resource_id])
      end
      @geolocation = geo
      @geolocation_box = geo.geolocation_box
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

    # geolocation exists with params resource_id, latitude, longitude
    def geolocation_by_box(object_params)
      box_params = object_params
      n_lat, e_long = box_params[:ne_latitude].to_d, box_params[:ne_longitude].to_d
      s_lat, w_long = box_params[:sw_latitude].to_d, box_params[:sw_longitude].to_d
      n_lat, s_lat = s_lat, n_lat if n_lat < s_lat
      e_long, w_long = w_long, e_long if e_long < w_long
      boxes = GeolocationBox.from_resource_id(params[:resource_id]).
          where(ne_latitude: n_lat, ne_longitude: e_long, sw_latitude: s_lat, sw_longitude: w_long)
      return nil if boxes.length < 1
      boxes.first.geolocation
    end

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