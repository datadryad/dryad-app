# This class is only for internal use and is not exposed to the public since it may include reports for
# files that we don't own (at Zenodo) and would only be used by our SensitiveData checker or perhaps a view
# and limited to roles that can access

# expect URLs to look like /api/v2/files/<file-id>/sensitiveDataReport
# and do only bare output of data for our own use.  Only enable PUT and GET
module StashApi
  class ExternalReportsController < ApiApplicationController

    before_action :require_json_headers
    before_action :force_json_content_type
    before_action :require_file # this is different for this than for files
    before_action :doorkeeper_authorize!, only: %i[update]
    before_action :require_api_user, only: %i[update]
    before_action :optional_api_user, only: %i[show]
    before_action :require_viewable_report, only: %i[show]
    before_action :require_permission, only: %i[update]
    before_action :require_correct_status, only: %i[update]

    # GET
    private

    def require_file
      @stash_file = StashEngine::GenericFile.where(id: params[:file_id]).first
      @resource = @stash_file&.resource # for require_permission to use
      render json: { error: 'not-found' }.to_json, status: 404 if @stash_file.nil? || @resource.nil?
    end

    def require_viewable_report
      @report = report_object
      render json: { error: 'not-found' }.to_json, status: 404 if @report.nil? ||
        !@stash_file.resource.may_view?(ui_user: @user)
    end

    def require_correct_status
      return if statuses.include?(params[:status])

      render json: { error: 'incorrect status set' }.to_json, status: 400
    end

    def report_object
      raise NotImplementedError, 'Subclasses must implement report_object'
    end

    def statuses
      raise NotImplementedError, 'Subclasses must implement statuses'
    end
  end
end
