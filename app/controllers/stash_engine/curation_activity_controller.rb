module StashEngine
  class CurationActivityController < ApplicationController
    before_action :require_user_login
    helper AdminDatasetsHelper

    # GET /resources/{id}/curation_activities
    def index
      authorize %i[stash_engine curation_activity]
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
      authorize %i[stash_engine curation_activity]
      @resource = Identifier.find_by_id(params[:id]).latest_resource
      @curation_activity = CurationActivity.create(resource_id: @resource.id, user_id: current_user.id,
                                                   status: @resource.last_curation_activity&.status,
                                                   note: params[:stash_engine_curation_activity][:note])
      @resource.reload
    end

    # this is used for user notes about file changes
    def file_note
      # only add to latest resource and after latest curation activity, no matter if this page is stale or whatever
      authorize %i[stash_engine curation_activity]
      @resource = Resource.find(params[:id])
      if params[:note_id]
        curation_activity = CurationActivity.where(id: params[:note_id]).first
        curation_activity.update(note: "User described file changes: #{params[:note]}")
      else
        curation_activity = CurationActivity.create(resource_id: @resource.id, user_id: current_user.id,
                                                    status: @resource.last_curation_activity&.status,
                                                    note: "User described file changes: #{params[:note]}")
      end
      @resource.reload
      render json: { note: curation_activity }
    end

    private

    def curation_activity_params
      params.require(:stash_engine_curation_activity).permit(:resource_id, :status, :note)
    end

  end
end
