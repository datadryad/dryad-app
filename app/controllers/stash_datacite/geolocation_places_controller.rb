require_dependency 'stash_datacite/application_controller'

module StashDatacite
  class GeolocationPlacesController < ApplicationController
    before_action :set_geolocation_place, only: [:edit, :update, :destroy]

    # # GET /geolocation_places/1/edit
    # def edit
    # end

    # POST /geolocation_places
    def create
      @geolocation_places = GeolocationPlace.where(resource_id: geolocation_place_params[:resource_id])
      @geolocation_points = GeolocationPoint.where(resource_id: geolocation_place_params[:resource_id])
      @geolocation_place = GeolocationPlace.new(geolocation_place_params)
      respond_to do |format|
        if @geolocation_place.save
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
    def destroy
      @geolocation_place.destroy
      redirect_to geolocation_places_url, notice: 'Geolocation place was successfully destroyed.'
    end

    private

    # Use callbacks to share common setup or constraints between actions.
    def set_geolocation_place
      @geolocation_place = GeolocationPlace.find(geolocation_place_params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def geolocation_place_params
      params.require(:geolocation_place).permit(:geo_location_place, :resource_id)
    end
  end
end
