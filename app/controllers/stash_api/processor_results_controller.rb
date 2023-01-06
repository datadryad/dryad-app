module StashApi
  class ProcessorResultsController < ApiApplicationController
    before_action :require_json_headers
    before_action :doorkeeper_authorize!
    before_action :require_api_user
    before_action :require_resource_from_id, only: %i[show update]
    # something sets the resource_id as the version_id
    before_action -> { require_resource_id(resource_id: params[:version_id]) }, only: %i[index create]
    before_action :require_permission # takes user and resource to determine

    # GET /api/v2/processor_results/:id
    def show
      render json: @processor_result
    end

    # GET /versions/<resource-id>/processor_results
    def index
      render json: @resource.processor_results
    end

    # POST /versions/<resource-id>/processor_results
    def create
      @processor_result = StashEngine::ProcessorResult.create(
        resource_id: @resource.id,
        processing_type: params[:processing_type],
        parent_id: params[:parent_id],
        completion_state: params[:completion_state],
        message: params[:message],
        structured_info: params[:structured_info]
      )
      render json: @processor_result
    end

    # PUT /processor_results/<id>
    def update
      permitted = params.permit(:processing_type, :parent_id, :completion_state, :message, :structured_info)
      @processor_result.update(permitted)
      render json: @processor_result
    end

    private def require_resource_from_id
      @processor_result = StashEngine::ProcessorResult.where(id: params[:id]).first
      @resource = @processor_result&.resource
      render json: { error: 'Not found' }.to_json, status: 404 unless @processor_result.present? && @resource.present?
    end
  end
end
