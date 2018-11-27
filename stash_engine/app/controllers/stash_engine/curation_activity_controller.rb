require_dependency 'stash_engine/application_controller'

module StashEngine
  class CurationActivityController < ApplicationController
    include SharedSecurityController

    before_action :require_curator

    # GET /resources/{id}/curation_activities
    def index
      @ident = Identifier.find_with_id(Resource.find_by!(id: params[:resource_id]).identifier_str)
      @curation_activities = CurationActivity.where(identifier_id: @ident.identifier_id).order(created_at: :desc) unless @ident.blank?
      respond_to do |format|
        format.html
        format.json { render json: @curation_activities }
      end
    end

    # POST /curation_activity
    def create

    end

  end
end
