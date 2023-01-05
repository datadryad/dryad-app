module StashApi
  class ProcessorResultsController < ApiApplicationController
    before_action :require_json_headers
    before_action :doorkeeper_authorize!
    before_action :require_api_user
    before_action :require_resource_from_id, only: [:show, :update]
    before_action :require_permission # takes @user and @resource to determine

    # GET /api/v2/processor_results/:id
    def show
      render json: @processor_result
    end

    # GET /versions/<resource-id>/processor_results
    def index
    end

    # POST /versions/<resource-id>/processor_results
    def create
    end

    # PUT /processor_results/<id>
    def update
    end

    private def require_resource_from_id
      @processor_result = StashEngine::ProcessorResult.where(id: params[:id]).first
      @resource = @processor_result&.resource
      render json: { error: 'Not found' }.to_json, status: 404 unless @processor_result.present? && @resource.present?
    end
  end
end
