require_dependency "stash_datacite/application_controller"

module StashDatacite
  class GeolocationBoxesController < ApplicationController
    before_action :set_geolocation_box, only: [:show, :edit, :update, :destroy]

    # GET /geolocation_boxes
    def index
      @geolocation_boxes = GeolocationBox.all
    end

    # GET /geolocation_boxes/1
    def show
    end

    # GET /geolocation_boxes/new
    def new
      @geolocation_box = GeolocationBox.new
    end

    # GET /geolocation_boxes/1/edit
    def edit
    end

    # POST /geolocation_boxes
    def create
      @geolocation_box = GeolocationBox.new(geolocation_box_params)

      if @geolocation_box.save
        redirect_to @geolocation_box, notice: 'Geolocation box was successfully created.'
      else
        render :new
      end
    end

    # PATCH/PUT /geolocation_boxes/1
    def update
      if @geolocation_box.update(geolocation_box_params)
        redirect_to @geolocation_box, notice: 'Geolocation box was successfully updated.'
      else
        render :edit
      end
    end

    # DELETE /geolocation_boxes/1
    def destroy
      @geolocation_box.destroy
      redirect_to geolocation_boxes_url, notice: 'Geolocation box was successfully destroyed.'
    end

    private
      # Use callbacks to share common setup or constraints between actions.
      def set_geolocation_box
        @geolocation_box = GeolocationBox.find(params[:id])
      end

      # Only allow a trusted parameter "white list" through.
      def geolocation_box_params
        params.require(:geolocation_box).permit(:sw_latitude, :ne_latitude, :sw_longitude, :ne_longitude, :resource_id)
      end
  end
end
