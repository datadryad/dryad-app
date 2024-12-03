module StashEngine

  # Mails users about submissions
  class NotificationsMailer < ApplicationMailer

    def health_status_change(status_code, health_status)
      @status_code = status_code
      @health_status = health_status

      mail(to: 'devs@datadryad.org', subject: "#{rails_env}Health check status changed - #{status_code}")
    end
  end
end
