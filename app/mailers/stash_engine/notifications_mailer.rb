module StashEngine

  # Mails users about submissions
  class NotificationsMailer < ApplicationMailer

    def health_status_change(status_code, health_status)
      @status_code = status_code
      @health_status = health_status

      mail(to: 'devs@datadryad.org', subject: "#{rails_env}Health check status changed - #{status_code}")
    end

    def submission_queue_too_large(count)
      @count = count

      mail(to: 'devs@datadryad.org', subject: "#{rails_env}Submission queue too large")
    end

    def certbot_expiration(expiration_days)
      @expiration_days = expiration_days

      mail(to: 'devs@datadryad.org', subject: "#{rails_env}🚨 Shibboleth SSL Cert expires in #{expiration_days} days!")
    end

    def nih_child_missing(contributor_id, api_response = {})
      @response = api_response
      @contributor_id = contributor_id

      mail(to: 'devs@datadryad.org', subject: "#{rails_env}🚨 NIH/NSF ROR could not be matched!")
    end

    def s3_lifetime_policy
      mail(to: 'devs@datadryad.org', subject: "#{rails_env}🚨 S3 Lifetime Policy not validated!")
    end

    def csp_violations
      day = 1.day.ago
      reports = CspReport.where(created_at: [day.beginning_of_day..day.end_of_day]).count
      puts @text = "There were #{reports} CSP violations reports for #{day.to_date}"

      mail(to: 'devs@datadryad.org', subject: "#{rails_env}🚨 #{reports} CSP Violations for #{day.to_date}!")
    end
  end
end
