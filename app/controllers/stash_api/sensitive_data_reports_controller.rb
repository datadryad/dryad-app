# This class is only for internal use and is not exposed to the public since it may include reports for
# files that we don't own (at Zenodo) and would only be used by our SensitiveData checker or perhaps a view
# and limited to roles that can access

# expect URLs to look like /api/v2/files/<file-id>/sensitiveDataReport
# and do only bare output of data for our own use.  Only enable PUT and GET
module StashApi
  class SensitiveDataReportsController < ExternalReportsController
    # GET
    def show
      @api_report = StashApi::SensitiveDataReport.new(file_obj: @stash_file, result_obj: @report)
      render json: @api_report.metadata
    end

    # PUT
    def update
      # only json for report and status will be updated, the rest is automatically updated
      report = @stash_file.sensitive_data_report
      report = StashEngine::SensitiveDataReport.new(generic_file_id: @stash_file.id) if report.nil?
      report.update(report: params[:report], status: params[:status])
      @api_report = StashApi::SensitiveDataReport.new(file_obj: @stash_file, result_obj: report)
      render json: @api_report.metadata
    end

    private

    def report_object
      @stash_file&.sensitive_data_report
    end

    def statuses
      StashEngine::SensitiveDataReport.statuses.keys
    end
  end
end
