class ScholarOneController < ApplicationController

  def notification
    if params[:taskStatus].downcase == 'completed' && params[:subscriptionType].downcase == 'task_status_change'
      status = metadata[:documentStatusName].downcase
      if status.in?(%w[accepted rejected])
        metadata = Integrations::ScholarOne.new.manuscript_metadata(params[:submissionId])
        Manuscript::ScholarOneService.new(metadata).create
      end
    end

    head :ok
  end
end
