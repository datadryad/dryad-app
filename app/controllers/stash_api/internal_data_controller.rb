# :nocov:
module StashApi
  class InternalDataController < ApiApplicationController
    before_action :require_json_headers
    before_action :doorkeeper_authorize!
    before_action :require_api_user
    before_action :require_min_app_admin
    before_action -> { require_stash_identifier(doi: params[:dataset_id]) }, only: %i[index create]

    # GET /internal_data/{id}
    def show
      @internal_data = StashEngine::InternalDatum.find(params[:id])
      render json: @internal_data
    end

    # GET /datasets/{dataset_id}/internal_data
    def index
      @internal_data = StashEngine::InternalDatum.where(identifier_id: @stash_identifier.id)
      @internal_data = @internal_data.data_type(params[:data_type]) if params.key?(:data_type)
      render json: @internal_data
    end

    # POST /datasets/{dataset_id}/internal_data
    def create
      @datum = StashEngine::InternalDatum.new(params[:internal_datum])
      @datum.update!(identifier_id: @stash_identifier.id)
      render json: @datum
    end

    # PUT /internal_data/{id}
    def update
      @internal_data = StashEngine::InternalDatum.find(params[:id])
      @internal_data.update!(params[:internal_datum])
      render json: @internal_data
    end

    # DELETE /internal_data/{id}
    def destroy
      StashEngine::InternalDatum.destroy(params[:id])
      render json: { status: "Internal datum with identifier #{params[:id]} has been successfully deleted." }.to_json, status: 200
    end
  end
end
# :nocov:
