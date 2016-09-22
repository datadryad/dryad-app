require_dependency 'stash_datacite/application_controller'

module StashDatacite
  class GeolocationPlacesController < ApplicationController
    before_action :set_geolocation_place, only: [:edit, :update, :delete]

    # GET /geolocation_places/
    def places_coordinates
      @geolocation_places =  geo_places(params[:resource_id])
      respond_to do |format|
        format.html
        format.json { render json: @geolocation_places }
      end
    end


    # POST Leaflet AJAX create
    def map_coordinates
      geo = geolocation_by_place
      unless geo
        p = params.except(:controller, :action)
        geo = Geolocation.new_geolocation(place: p[:geo_location_place],
                                          point: [p[:latitude], p[:longitude]],
                                          box:   [p[:ne_latitude], p[:ne_longitude],p[:sw_latitude], p[:sw_longitude]],
                                          resource_id: params[:resource_id])
      end
      @geolocation_place = geo.geolocation_place
      respond_to do |format|
        if @geolocation_place.save
          @resource = StashDatacite.resource_class.find(params[:resource_id])
          @geolocation_places = GeolocationPlace.from_resource_id(params[:resource_id])
          format.js
        else
          format.html { render :new }
        end
      end
    end

    # DELETE /geolocation_places/1
    def delete
      #@latitude = @geolocation_place.latitude
      #@longitude = @geolocation_place.longitude
      geo = @geolocation_place.try(:geolocation)
      geo.destroy_place
      geo.destroy_box
      geo.destroy_point
      @resource = StashDatacite.resource_class.find(params[:resource_id])
      @geolocation_places = GeolocationPlace.from_resource_id(params[:resource_id])
      respond_to do |format|
        format.js
      end
    end

    private
    # Use callbacks to share common setup or constraints between actions.

    def geo_places(resource_id)
      places = []
      geo_places = GeolocationPlace.from_resource_id(resource_id)
      geo_places.each do |geo_pl|
        geolocation_place = []
        geolocation_place << geo_pl.geo_location_place << geo_pl.geolocation.geolocation_point.latitude << geo_pl.geolocation.geolocation_point.latitude << geo_pl.id
        places << geolocation_place
        return places
      end
    end

    def geolocation_by_place
      place_params = params.except(:controller, :action)
      places = GeolocationPlace.from_resource_id(params[:resource_id]).
                                where(geo_location_place: place_params[:geo_location_place])
      return nil if places.length < 1
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
