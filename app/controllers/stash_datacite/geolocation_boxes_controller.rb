module StashDatacite
  class GeolocationBoxesController < ApplicationController
    before_action :set_geolocation_box, only: %i[show edit update delete]
    before_action :ajax_require_modifiable, only: %i[map_coordinates create delete]

    # # GET /geolocation_boxes/
    def boxes_coordinates
      @geolocation_boxes = GeolocationBox.select(:resource_id, :sw_latitude, :sw_longitude, :ne_latitude, :ne_longitude)
        .only_geo_bbox(params[:resource_id])
      respond_to do |format|
        format.json { render json: @geolocation_boxes }
      end
    end

    # # GET /geolocation_boxes/1/edit
    # def edit
    # end

    # POST /geolocation_boxes
    def map_coordinates
      loc = find_or_create_geolocation(params)
      respond_to do |format|
        @geolocation_boxes = GeolocationBox.only_geo_bbox(resource.id)
        @geolocation_box = loc.geolocation_box
        format.js { render template: 'stash_datacite/geolocation_boxes/create.js.erb' }
      end
    end

    # POST /geolocation_boxes
    def create
      @geolocation = find_or_create_geolocation(params[:geolocation_box])
      @geolocation_box = @geolocation.geolocation_box
      respond_to do |format|
        @geolocation_boxes = GeolocationBox.only_geo_bbox(resource.id)
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

      @geolocation_boxes = GeolocationBox.only_geo_bbox(resource.id)
      respond_to { |format| format.js }
    end

    private

    def resource
      @resource ||= if params[:action] == 'delete'
                      GeolocationBox.find(params[:id]).geolocation.resource # ignore the resource_id supplied since we can infer it
                    else
                      StashEngine::Resource.find(params[:resource_id])
                    end
    end

    # geolocation exists with params resource_id, latitude, longitude
    def find_geolocation_by_box(object_params)
      n_lat, e_long, s_lat, w_long = coordinates_from(object_params)
      boxes = GeolocationBox
        .only_geo_bbox(params[:resource_id])
        .where(ne_latitude: n_lat, ne_longitude: e_long, sw_latitude: s_lat, sw_longitude: w_long)
      return nil if boxes.empty?

      boxes.first.geolocation
    end

    def coordinates_from(object_params)
      n_lat = object_params[:ne_latitude].to_d
      e_long = object_params[:ne_longitude].to_d
      s_lat = object_params[:sw_latitude].to_d
      w_long = object_params[:sw_longitude].to_d
      n_lat, s_lat = s_lat, n_lat if n_lat < s_lat
      e_long, w_long = w_long, e_long if e_long < w_long
      [n_lat, e_long, s_lat, w_long]
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

    def find_or_create_geolocation(box_params)
      existing = find_geolocation_by_box(box_params)
      return existing if existing

      Geolocation.new_geolocation(box: [box_params[:ne_latitude], box_params[:ne_longitude],
                                        box_params[:sw_latitude], box_params[:sw_longitude]],
                                  resource_id: params[:resource_id])
    end
  end
end
