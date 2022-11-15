# This class is only for internal use and is not exposed to the public since it may include reports for
# files that we don't own (at Zenodo) and would only be used by our Frictionless checker or perhas a view
# and limited to roles that can access

# expect URLs to look like /api/v2/files/<file-id>/frictionlessReport
# and do only bare output of data for our own use.  Only enable PUT and GET
module StashApi
  class FrictionlessReportsController < ApiApplicationController

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
    def show
      @api_report = StashApi::FrictionlessReport.new(file_obj: @stash_file, fric_obj: @report)
      respond_to do |format|
        format.any { render json: @api_report.metadata }
      end
    end

    # PUT
    def update
      # only json for report and status will be updated, the rest is automatically updated
      fr = @stash_file.frictionless_report
      fr = StashEngine::FrictionlessReport.new(generic_file_id: @stash_file.id) if fr.nil?
      fr.update(report: params[:report], status: params[:status])
      @api_report = StashApi::FrictionlessReport.new(file_obj: @stash_file, fric_obj: fr)
      respond_to do |format|
        format.any { render json: @api_report.metadata }
      end
    end

    def require_file
      @stash_file = StashEngine::GenericFile.where(id: params[:file_id]).first
      @resource = @stash_file&.resource # for require_permission to use
      render json: { error: 'not-found' }.to_json, status: 404 if @stash_file.nil? || @resource.nil?
    end

    def require_viewable_report
      @report = @stash_file&.frictionless_report
      render json: { error: 'not-found' }.to_json, status: 404 if @report.nil? ||
        !@stash_file.resource.may_view?(ui_user: @user)
    end

    def require_correct_status
      return if StashEngine::FrictionlessReport.statuses.keys.include?(params[:status])

      render json: { error: 'incorrect status set' }.to_json, status: 400
    end

  end
end
