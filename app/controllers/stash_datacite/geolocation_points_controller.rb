module StashDatacite
  class GeolocationPointsController < ApplicationController
    before_action :set_geolocation_point, only: %i[edit update delete]
    before_action :ajax_require_modifiable, only: %i[map_coordinates update_coordinates create delete]

    def index
      respond_to do |format|
        @geolocation_points = GeolocationPoint.only_geo_points(params[:resource_id])
        @resource = StashEngine::Resource.find(params[:resource_id])
        format.js
      end
    end

    # GET Leaflet AJAX index
    def points_coordinates
      respond_to do |format|
        @geolocation_points = GeolocationPoint.select(:resource_id, :id, :latitude, :longitude)
          .only_geo_points(params[:resource_id])
        format.json { render json: @geolocation_points }
      end
    end

    # POST Leaflet AJAX create
    def map_coordinates
      loc = find_or_create_geolocation(params)
      @geolocation_point = loc.geolocation_point
      respond_to do |format|
        format.json { render json: @geolocation_point.id }
      end
    end

    # POST Leaflet AJAX update
    def update_coordinates
      # this already blocks access since this find_point_from checks both id and resource
      @geolocation_point = find_point_from(params)
      respond_to do |format|
        if update_point(@geolocation_point, params)
          format.json { render json: @geolocation_point.id }
        else
          format.html { render :new }
        end
      end
    end

    # POST /geolocation_points
    def create
      loc = find_or_create_geolocation(params[:geolocation_point])
      @geolocation_point = loc.geolocation_point
      @resource = StashEngine::Resource.find(params[:resource_id])
      respond_to do |format|
        @geolocation_points = GeolocationPoint.only_geo_points(params[:resource_id])
        format.js
      end
    end

    # DELETE /geolocation_points/1 && # DELETE Leaflet AJAX update
    def delete
      @latitude = @geolocation_point.latitude
      @longitude = @geolocation_point.longitude
      @geolocation_point.try(:geolocation).try(:destroy_point)
      # @resource = StashEngine::Resource.find(params[:resource_id])
      @geolocation_points = GeolocationPoint.only_geo_points(resource.id)
      respond_to(&:js)
    end

    private

    def resource
      @resource ||= if params[:action] == 'delete'
                      GeolocationPoint.find(params[:id]).geolocation.resource # ignore the resource_id supplied since we can infer it
                    else
                      StashEngine::Resource.find(params[:resource_id])
                    end
    end

    def find_point_from(params)
      GeolocationPoint.where(id: params[:id]).from_resource_id(params[:resource_id]).first
    end

    def update_point(point, params)
      point.update(latitude: params[:latitude], longitude: params[:longitude])
    end

    def find_or_create_geolocation(pt_params)
      existing = find_geolocation_by_point(pt_params)
      return existing if existing

      Geolocation.new_geolocation(
        point: [
          pt_params[:latitude],
          pt_params[:longitude]
        ],
        resource_id: params[:resource_id]
      )
    end

    # geolocation exists with params resource_id, latitude, longitude
    def find_geolocation_by_point(object_params)
      points = GeolocationPoint
        .only_geo_points(params[:resource_id])
        .where(latitude: object_params[:latitude], longitude: object_params[:longitude])
      return nil if points.empty?

      points.first.geolocation
    end

    # Use callbacks to share common setup or constraints between actions.
    def set_geolocation_point
      @geolocation_point = GeolocationPoint.find(params[:id])
    end

    # Only allow a trusted parameter white list" through.
    def geolocation_point_params
      params.require(:geolocation_point).permit(:id, :latitude, :longitude, :resource_id)
    end
  end
end
