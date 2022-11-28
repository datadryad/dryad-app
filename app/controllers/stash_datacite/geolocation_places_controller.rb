module StashDatacite
  class GeolocationPlacesController < ApplicationController
    before_action :set_geolocation_place, only: %i[edit update delete]
    before_action :ajax_require_modifiable, only: %i[map_coordinates delete]

    # GET /geolocation_places/
    def places_coordinates
      @geolocation_places = GeolocationPlace.geo_places(params[:resource_id])
      respond_to do |format|
        format.json { render json: @geolocation_places }
      end
    end

    # POST Leaflet AJAX create
    def map_coordinates
      loc = find_or_create_geolocation(params)
      @geolocation_place = loc.geolocation_place
      respond_to do |format|
        @geolocation_place.save ? format_js(format, params) : format.html { render :new }
      end
    end

    # DELETE /geolocation_places/1
    def delete
      geo = @geolocation_place.try(:geolocation)
      geo.destroy_place
      geo.destroy_box
      geo.destroy_point
      respond_to { |format| format_js(format, params) }
    end

    private

    def resource
      @resource ||= if params[:action] == 'delete'
                      GeolocationPlace.find(params[:id]).geolocation.resource # ignore the resource_id supplied since we can infer it
                    else
                      StashEngine::Resource.find(params[:resource_id])
                    end
    end

    def format_js(format, params)
      @resource = StashEngine::Resource.find(params[:resource_id])
      @geolocation_places = GeolocationPlace.from_resource_id(params[:resource_id])
      format.js
    end

    def find_or_create_geolocation(params)
      existing = find_geolocation_by_place(params)
      return existing if existing

      new_geolocation_from(params)
    end

    def new_geolocation_from(params)
      Geolocation.new_geolocation(
        place: params[:geo_location_place],
        point: [
          params[:latitude],
          params[:longitude]
        ],
        box: params[:bbox].try(:reverse),
        resource_id: params[:resource_id]
      )
    end

    def find_geolocation_by_place(params)
      places = GeolocationPlace
        .from_resource_id(params[:resource_id])
        .where(geo_location_place: params[:geo_location_place])
      return nil if places.empty?

      places.first.geolocation
    end

    def set_geolocation_place
      @geolocation_place = GeolocationPlace.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def geolocation_place_params
      params.require(:geolocation_place).permit(:id, :geo_location_place, :latitude, :longitude, :resource_id)
    end
  end
end
