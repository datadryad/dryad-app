require_dependency 'stash_engine/application_controller'

module StashEngine
  class CurationActivityController < ApplicationController
    include SharedSecurityController

    before_action :require_curator, only: :index
    before_action :ajax_require_curator, only: :status_change

    # GET /resources/{id}/curation_activities
    def index
      @ident = Identifier.find_with_id(Resource.find_by!(id: params[:resource_id]).identifier_str)
      @curation_activities = CurationActivity.where(identifier_id: @ident.identifier_id).order(created_at: :desc) unless @ident.blank?
      respond_to do |format|
        format.html
        format.json { render json: @curation_activities }
      end
    end

    # A special action for changing curation status from ajax and admin/curator area, creates new status
    # in list for identifier, which is the ID that is passed in.  It does ajax mumbo-jumbo for admin area.
    # this isn't RESTful
    def status_change
      respond_to do |format|
        format.js do
          @activity = CurationActivity.create(identifier_id: params[:id], status: params[:status] , user_id: current_user.id,
                                              note: params[:note])
        end
      end
    end
  end
end
