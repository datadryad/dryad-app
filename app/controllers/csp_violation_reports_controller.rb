class CspViolationReportsController < ApplicationController

  skip_forgery_protection

  def create
    report = JSON.parse(request.body.read)
    StashEngine::NotificationsMailer.csp_violation(report).deliver_now
    head :ok
  end
end
