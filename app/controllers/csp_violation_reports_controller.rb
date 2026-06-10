class CspViolationReportsController < ApplicationController

  skip_forgery_protection

  def create
    report = JSON.parse(request.body.read)
    CspReport.create(
      ip: request.remote_ip,
      user_agent: request.user_agent,
      blocked_uri: report['csp-report']['blocked-uri'],
      url: report['csp-report']['document-uri'],
      directive: report['csp-report']['effective-directive'],
      status_code: report['csp-report']['status-code'],
      report: report
    )
    head :ok
  end
end
