require_dependency 'stash_engine/application_controller'

module StashEngine
  class InternalDataController < ApplicationController
    include SharedSecurityController

    before_action :require_curator

    # GET /resources/{id}/internal_data
    def index
      ident = Identifier.find_with_id(Resource.find_by!(id: params[:resource_id]).identifier_str)
      @internal_data = InternalDatum.where(identifier_id: ident.identifier_id) unless ident.blank?
      respond_to do |format|
        format.html
        format.json { render json: @internal_data }
      end
    end

  end
end
