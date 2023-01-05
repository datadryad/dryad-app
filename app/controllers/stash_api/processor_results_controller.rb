module StashApi
  class ProcessorResultsController < ApiApplicationController
    before_action :require_json_headers
    before_action :doorkeeper_authorize!
    before_action :require_api_user
    before_action :require_limited_curator

    # these use shallow nested routing on version (ie resource)

    # GET /processor_result/<id>
    def show
    end

    # GET /versions/<resource-id>/processor_result
    def index
    end

    # POST /versions/<resource-id>/processor_result
    def create
    end

    # PUT /processor_result/<id>
    def update
    end
  end
end
