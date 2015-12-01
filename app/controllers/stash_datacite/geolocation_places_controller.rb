require_dependency "stash_datacite/application_controller"

module StashDatacite
  class GeolocationPlacesController < ApplicationController
    before_action :set_geolocation_place, only: [:show, :edit, :update, :destroy]

    # GET /geolocation_places
    def index
      @geolocation_places = GeolocationPlace.all
    end

    # GET /geolocation_places/1
    def show
    end

    # GET /geolocation_places/new
    def new
      @geolocation_place = GeolocationPlace.new
    end

    # GET /geolocation_places/1/edit
    def edit
    end

    # POST /geolocation_places
    def create
      @geolocation_place = GeolocationPlace.new(geolocation_place_params)

      if @geolocation_place.save
        redirect_to @geolocation_place, notice: 'Geolocation place was successfully created.'
      else
        render :new
      end
    end

    # PATCH/PUT /geolocation_places/1
    def update
      if @geolocation_place.update(geolocation_place_params)
        redirect_to @geolocation_place, notice: 'Geolocation place was successfully updated.'
      else
        render :edit
      end
    end

    # DELETE /geolocation_places/1
    def destroy
      @geolocation_place.destroy
      redirect_to geolocation_places_url, notice: 'Geolocation place was successfully destroyed.'
    end

    private
      # Use callbacks to share common setup or constraints between actions.
      def set_geolocation_place
        @geolocation_place = GeolocationPlace.find(params[:id])
      end

      # Only allow a trusted parameter "white list" through.
      def geolocation_place_params
        params.require(:geolocation_place).permit(:geo_location_place, :resource_id)
      end
  end
end
