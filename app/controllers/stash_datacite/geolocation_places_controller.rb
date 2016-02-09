require_dependency 'stash_datacite/application_controller'

module StashDatacite
  class GeolocationPlacesController < ApplicationController
    before_action :set_geolocation_place, only: [:edit, :update, :delete]

    # # GET /geolocation_points/
    def places_coordinates
      @geolocation_places = GeolocationPlace.select(:geo_location_place).where(resource_id: params[:resource_id])
      respond_to do |format|
        format.html
        format.json { render json: @geolocation_places }
      end
    end

    # POST Leaflet AJAX create
    def map_coordinates
      geolocation_place_params = params.except(:controller, :action)
      @geolocation_place = GeolocationPlace.new(geolocation_place_params.permit!)
      respond_to do |format|
        if @geolocation_place.save
          @geolocation_places = GeolocationPlace.where(resource_id: params[:resource_id])
          format.js { render template: 'stash_datacite/geolocation_places/map_coordinates.js.erb' }
        else
          format.html { render :new }
        end
      end
    end

    # # GET /geolocation_places/1/edit
    # def edit
    # end

    # POST /geolocation_places
    def create
      @geolocation_place = GeolocationPlace.new(geolocation_place_params)
      respond_to do |format|
        if @geolocation_place.save
          @geolocation_places = GeolocationPlace.where(resource_id: geolocation_place_params[:resource_id])
          format.js
        else
          format.html { render :new }
        end
      end
    end

    # # PATCH/PUT /geolocation_places/1
    # def update
    #   respond_to do |format|
    #     if if @geolocation_place.update(geolocation_place_params)
    #       format.js { render template: 'stash_datacite/shared/update.js.erb' }
    #     else
    #       format.html { render :edit }
    #     end
    #   end
    # end

    # DELETE /geolocation_places/1
    def delete
      @latitude = @geolocation_place.latitude
      @longitude = @geolocation_place.longitude
      @geolocation_place.destroy
      respond_to do |format|
        format.html { redirect_to :back}
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
