# This class is only for internal use and is not exposed to the public since it may include reports for
# files that we don't own (at Zenodo) and would only be used by our Frictionless checker or perhaps a view
# and limited to roles that can access

# expect URLs to look like /api/v2/files/<file-id>/frictionlessReport
# and do only bare output of data for our own use.  Only enable PUT and GET
module StashApi
  class FrictionlessReportsController < ExternalReportsController

    def show
      @api_report = StashApi::FrictionlessReport.new(file_obj: @stash_file, fric_obj: @report)
      render json: @api_report.metadata
    end

    # PUT
    def update
      # only json for report and status will be updated, the rest is automatically updated
      fr = @stash_file.frictionless_report
      fr = StashEngine::FrictionlessReport.new(generic_file_id: @stash_file.id) if fr.nil?
      fr.update(report: params[:report], status: params[:status])
      @api_report = StashApi::FrictionlessReport.new(file_obj: @stash_file, fric_obj: fr)
      render json: @api_report.metadata
    end

    private

    def report_object
      @stash_file&.frictionless_report
    end

    def statuses
      StashEngine::FrictionlessReport.statuses.keys
    end
  end
end
