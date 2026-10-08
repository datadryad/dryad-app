class ScholarOneController < ApplicationController

  def notification
    if params[:taskStatus].downcase == 'completed' && params[:subscriptionType].downcase == 'task_status_change'
      status = params[:documentStatusName].downcase
      if status.in?(%w[accepted rejected])
        journal = ExternalIntegration.where("details->'$.site_name' = ?", params[:siteName]).first.integrator
        return if journal.nil?

        metadata = Integrations::ScholarOne.new(journal).manuscript_metadata(params[:submissionId])
        Manuscript::ScholarOneService.new(metadata).create
      end
    end

    head :ok
  end
end
