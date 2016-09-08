require_dependency 'stash_datacite/application_controller'

module StashDatacite
  class GeolocationPlacesController < ApplicationController
    before_action :set_geolocation_place, only: [:edit, :update, :delete]

    # GET /geolocation_places/
    def places_coordinates
      @geolocation_places = GeolocationPlace.select(:id, :geo_location_place, :latitude, :longitude)
                                            .where(resource_id: params[:resource_id])
      respond_to do |format|
        format.html
        format.json { render json: @geolocation_places }
      end
    end

    # POST Leaflet AJAX create
    def map_coordinates
      geolocation_place_params = params.except(:controller, :action)
      @geolocation_place = GeolocationPlace.new(geolocation_place_params.permit!)
      @resource = StashDatacite.resource_class.find(params[:resource_id])
      respond_to do |format|
        if @geolocation_place.save
          @geolocation_places = GeolocationPlace.where(resource_id: params[:resource_id])
          format.js
        else
          format.html { render :new }
        end
      end
    end

    # DELETE /geolocation_places/1
    def delete
      @latitude = @geolocation_place.latitude
      @longitude = @geolocation_place.longitude
      @geolocation_place.destroy
      @resource = StashDatacite.resource_class.find(params[:resource_id])
      @geolocation_places = GeolocationPlace.where(resource_id: params[:resource_id])
      respond_to do |format|
        format.js
      end
    end

    private

    # Use callbacks to share common setup or constraints between actions.
    def set_geolocation_place
      @geolocation_place = GeolocationPlace.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def geolocation_place_params
      params.require(:geolocation_place).permit(:id, :geo_location_place, :latitude, :longitude, :resource_id)
    end
  end
end
