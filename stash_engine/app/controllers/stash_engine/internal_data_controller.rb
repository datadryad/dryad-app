require_dependency 'stash_engine/application_controller'

module StashEngine
  class InternalDataController < ApplicationController
    before_action :require_login

    # GET /resources/{id}/internal_data
    def index
      @internal_data = InternalDatum.where(resource_id: params[:resource_id])
      respond_to do |format|
        format.html
        format.json { render json: @internal_data }
      end
    end

  end
end
