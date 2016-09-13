require_dependency 'stash_datacite/application_controller'

module StashDatacite
  class GeolocationPointsController < ApplicationController
    before_action :set_geolocation_point, only: [:edit, :update, :delete]

    def index
      respond_to do |format|
        @geolocation_points = GeolocationPoint.where(resource_id: params[:resource_id])
        @resource = StashDatacite.resource_class.find(params[:resource_id])
        format.js
      end
    end

    # GET Leaflet AJAX index
    def points_coordinates
      respond_to do |format|
        @geolocation_points = GeolocationPoint.select(:id, :latitude, :longitude).where(resource_id: params[:resource_id])
        format.html
        format.json { render json:  @geolocation_points }
      end
    end

    # POST Leaflet AJAX create
    def map_coordinates
      geolocation_point_params = params.except(:controller, :action, :id)
      @geolocation_point = GeolocationPoint.find_or_initialize_by(geolocation_point_params.permit!)
      respond_to do |format|
        if @geolocation_point.save
          format.json { render json: @geolocation_point.id }
        else
          format.html { render :new }
        end
      end
    end

    # POST Leaflet AJAX update
    def update_coordinates
      @geolocation_point = GeolocationPoint.where(id: params[:id], resource_id: params[:resource_id]).first
      geolocation_point_params = params.except(:controller, :action)
      respond_to do |format|
        if @geolocation_point.update(geolocation_point_params.permit!)
          format.json { render json: @geolocation_point.id }
        else
          format.html { render :new }
        end
      end
    end

    # POST /geolocation_points
    def create
      @geolocation_point = GeolocationPoint.find_or_initialize_by(geolocation_point_params)
      @resource = StashDatacite.resource_class.find(geolocation_point_params[:resource_id])
      respond_to do |format|
        if @geolocation_point.save
          @geolocation_points = GeolocationPoint.where(resource_id: geolocation_point_params[:resource_id])
          format.js
        else
          format.html { render :new }
        end
      end
    end

    # DELETE /geolocation_points/1 && # DELETE Leaflet AJAX update
    def delete
      @latitude = @geolocation_point.latitude
      @longitude = @geolocation_point.longitude
      @geolocation_point.destroy
      @resource = StashDatacite.resource_class.find(params[:resource_id])
      @geolocation_points = GeolocationPoint.where(resource_id: params[:resource_id])
      respond_to do |format|
        format.js
      end
    end

    private

    # Use callbacks to share common setup or constraints between actions.
    def set_geolocation_point
      @geolocation_point = GeolocationPoint.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def geolocation_point_params
      params.require(:geolocation_point).permit(:id, :latitude, :longitude, :resource_id)
    end
  end
end
