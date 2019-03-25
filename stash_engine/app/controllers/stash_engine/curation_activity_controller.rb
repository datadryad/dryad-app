require_dependency 'stash_engine/application_controller'

module StashEngine
  class CurationActivityController < ApplicationController
    include SharedSecurityController

    before_action :require_curator, only: :index
    before_action :ajax_require_curator, only: :status_change

    # GET /resources/{id}/curation_activities
    def index
      resource = Resource.includes(:identifier, :curation_activities).find(params[:resource_id])
      @ident = resource.identifier
      @curation_activities = resource.curation_activities.order(created_at: :desc)
      respond_to do |format|
        format.html
        format.json { render json: @curation_activities }
      end
    end

    # this is used by the 'add note, and only for curation history page'
    def curation_note
      # only add to latest resource and after latest curation activity, no matter if this page is stale or whatever
      @resource = Identifier.find_by_id(params[:id]).latest_resource
      @curation_activity = CurationActivity.create(
        status: @resource.current_curation_activity.status,
        note: params[:curation_activity][:note],
        resource_id: @resource.id,
        user_id: current_user.id
      )
    end

    private

    def curation_activity_params
      params.require(:curation_activity).permit(:resource_id, :status, :note)
    end

  end
end
