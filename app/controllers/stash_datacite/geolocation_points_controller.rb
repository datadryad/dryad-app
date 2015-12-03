require_dependency 'stash_datacite/application_controller'

module StashDatacite
  class GeolocationPointsController < ApplicationController
    before_action :set_geolocation_point, only: [:show, :edit, :update, :destroy]

    # GET /geolocation_points
    def index
      @geolocation_points = GeolocationPoint.all
    end

    # GET /geolocation_points/1
    def show
    end

    # GET /geolocation_points/new
    def new
      @geolocation_point = GeolocationPoint.new
    end

    # GET /geolocation_points/1/edit
    def edit
    end

    # POST /geolocation_points
    def create
      @geolocation_point = GeolocationPoint.new(geolocation_point_params)

      if @geolocation_point.save
        redirect_to @geolocation_point, notice: 'Geolocation point was successfully created.'
      else
        render :new
      end
    end

    # PATCH/PUT /geolocation_points/1
    def update
      if @geolocation_point.update(geolocation_point_params)
        redirect_to @geolocation_point, notice: 'Geolocation point was successfully updated.'
      else
        render :edit
      end
    end

    # DELETE /geolocation_points/1
    def destroy
      @geolocation_point.destroy
      redirect_to geolocation_points_url, notice: 'Geolocation point was successfully destroyed.'
    end

    private

    # Use callbacks to share common setup or constraints between actions.
    def set_geolocation_point
      @geolocation_point = GeolocationPoint.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def geolocation_point_params
      params.require(:geolocation_point).permit(:latitude, :longitude, :resource_id)
    end
  end
end
