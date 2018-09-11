require_dependency 'stash_api/application_controller'

module StashApi
  class InternalDataController < ApplicationController
    before_action :doorkeeper_authorize!

    def index
      @internal_data = StashEngine::InternalDatum.all
      respond_to do |format|
        format.json { render json: @internal_data }
      end
    end
    
    # GET /internal_data/{id}
    def show
      @internal_data = StashEngine::InternalDatum.where(resource_id: params[:id])
      @internal_data = @internal_data.data_type(params[:data_type]) if params.key?(:data_type)
      respond_to do |format|
        format.json { render json: @internal_data }
      end
    end

    # POST /internal_data
    def create
      params.permit!
      @datum = StashEngine::InternalDatum.new(params[:internal_datum])
      logger.debug @datum.save!
      render json: @datum
    end

    def update
      params.permit!
      @internal_data = StashEngine::InternalDatum.update(params[:internal_datum][:id], params[:internal_datum])
      respond_to do |format|
        format.json { render json: @internal_data }
      end
    end

    def destroy
      StashEngine::InternalDatum.destroy(params[:internal_datum][:id])
      index
    end
  end
end
