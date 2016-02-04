require_dependency 'stash_datacite/application_controller'

module StashDatacite
  class GeolocationPointsController < ApplicationController
    before_action :set_geolocation_point, only: [:edit, :update, :delete]

    # GET Leaflet AJAX index
    def points_coordinates
      @geolocation_points = GeolocationPoint.select(:id, :latitude, :longitude).where(resource_id: params[:resource_id])
      respond_to do |format|
        format.html
        format.json { render json:  @geolocation_points }
      end
    end

    # POST Leaflet AJAX create
    def map_coordinates
      geolocation_point_params = params.except(:controller, :action, :id)
      @geolocation_point = GeolocationPoint.new(geolocation_point_params.permit!)
      respond_to do |format|
        if @geolocation_point.save
          @geolocation_points = GeolocationPoint.where(resource_id: params[:resource_id])
          format.js { params[:id] = @geolocation_point.id }
          format.json
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
          @geolocation_points = GeolocationPoint.where(resource_id: params[:resource_id])
          format.js
        else
          format.html { render :new }
        end
      end
    end

    # POST /geolocation_points
    def create
      @geolocation_point = GeolocationPoint.new(geolocation_point_params)
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
      @geolocation_point.destroy
      respond_to do |format|
        @geolocation_points = GeolocationPoint.where(resource_id: params[:resource_id])
        format.html { redirect_to :back }
        format.js { render template: 'stash_datacite/geolocation_points/update_coordinates.js.erb' }
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
