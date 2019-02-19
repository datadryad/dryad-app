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

    def new
      @ident = Identifier.find_with_id(Resource.find_by!(id: params[:resource_id]).identifier_str)
    end

    # A special action for changing curation status from ajax and admin/curator area, creates new status
    # in list for identifier, which is the ID that is passed in.  It does ajax mumbo-jumbo for admin area.
    # this isn't RESTful
    # def create
    def status_change
      respond_to do |format|
        format.js do
          @resource = StashEngine::Resource.find(curation_activity_params[:resource_id])
          handle_status(@resource)
          @activity = @resource.reload.current_curation_activity
        end
      end
    end

    private

    def curation_activity_params
      params.require(:curation_activity).permit(:resource_id, :status, :note)
    end

    # Publish, embargo or simply change the status
    # rubocop:disable Metrics/AbcSize
    def handle_status(resource)
      case curation_activity_params[:status]
      when 'published'
        resource.publish!(current_user.id, Date.today, curation_activity_params[:note])
      when 'embargoed'
        resource.embargo!(current_user.id, Date.today + 1.year, curation_activity_params[:note])
      else
        CurationActivity.create(resource_id: @resource.id, user_id: current_user.id,
                                status: curation_activity_params[:status], note: curation_activity_params[:note])
      end
    end
    # rubocop:enable Metrics/AbcSize

  end
end
