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
    # rubocop:disable Metrics/MethodLength
    def status_change
      respond_to do |format|
        format.js do
          @resource = StashEngine::Resource.find(curation_activity_params[:resource_id])

          # If the user was only adding a note, NOT changing the status, then retrieve
          # the last curation status and use that
          status = if curation_activity_params[:status].blank?
                     @resource.current_curation_status
                   else
                     curation_activity_params[:status]
                   end
          @activity = CurationActivity.create(resource_id: @resource.id,
                                              note: curation_activity_params[:note],
                                              status: status, user_id: current_user.id)
          # If the user published the resource then set its publication_date to today
          if status == 'published'
            @resource.update(publication_date: formatted_html5_date(Date.today))

          # If the user embargoed the resource and there is no future publication date then
          # default the publication_date to 1 year out
          elsif status == 'embargoed' && (!@resource.publication_date.present? || @resource.publication_date < formatted_html5_date(Date.today))
            @resource.update(publication_date: formatted_html5_date(Date.today + 1.year))
          end
        end
      end
    end
    # rubocop:enable Metrics/MethodLength

    private

    def curation_activity_params
      params.require(:curation_activity).permit(:resource_id, :status, :note)
    end

  end
end
