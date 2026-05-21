class CspViolationReportsController < ApplicationController

  # skip_before_action :verify_authenticity_token
  skip_forgery_protection
  def create
    report = JSON.parse(request.body.read)
    StashEngine::NotificationsMailer.csp_violation(report).deliver_now
    head :ok
  end

  private

  def report_params

  end
end