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

    # Called from the StashEngine::Repository
    def error_report(resource, error)
      logger.warn("Unable to report update error #{error}; nil resource") unless resource.present?
      return unless resource.present?

      assign_variables(resource)
      @backtrace = error.full_message
      mail(to: @submission_error_emails, bcc: @bcc_emails,
           subject: "#{rails_env}Submitting dataset \"#{@title}\" (doi:#{@resource.identifier_value}) failed")
    end

    def general_error(resource, error_text)
      logger.warn("Unable to report update error #{error_text}; nil resource") unless resource.present?
      @zenodo_error_emails = APP_CONFIG['developer_email']
      return unless resource.present? && @zenodo_error_emails.present?

      @resource = resource

      @error_text = error_text
      mail(to: @zenodo_error_emails,
           subject: "#{rails_env}General error \"#{@resource.title.strip_tags}\" (doi:#{@resource.identifier_value})")
    end

    def integration_paused(journals)
      @journals = journals
      email = APP_CONFIG['developer_email']
      return unless @journals.present? && email.present?

      mail(to: email,
           subject: "#{rails_env}Journal integration issue")
    end

    def file_validation_error(file)
      logger.warn('Unable to validate file checksum; nil file') unless file.present?
      @zenodo_error_emails = APP_CONFIG['developer_email']
      return unless file.present? && @zenodo_error_emails.present?

      @file = file
      mail(to: @zenodo_error_emails,
           subject: "#{rails_env}File checksum validation error")
    end

    def merge_request(current_user, existing_user)
      @user = current_user
      @old = existing_user
      @helpdesk_email = APP_CONFIG['helpdesk_email']
      @submission_error_emails = APP_CONFIG['developer_email'] || [@helpdesk_email]
      mail(to: @helpdesk_email, bcc: @submission_error_emails, subject: "#{rails_env}User account merge request", reply_to: @old.email)
    end

    def dependency_offline(dependency, message)
      return unless dependency.present?

      @dependency = dependency
      @url = status_dashboard_url
      @submission_error_emails = APP_CONFIG['developer_email'] || [@helpdesk_email]
      @message = message
      mail(to: @submission_error_emails, bcc: @bcc_emails,
           subject: "#{rails_env}dependency offline: #{dependency.name}")
    end

    def zenodo_error(zenodo_copy_obj)
      @zen = zenodo_copy_obj
      logger.warn('Unable to report zenodo error, no zenodo copy object') unless @zen.present?
      return unless @zen.present?

      @zenodo_error_emails = APP_CONFIG['developer_email'] || [@helpdesk_email]

      mail(to: @zenodo_error_emails,
           subject: "#{rails_env}Failed to update Zenodo for #{@zen.identifier} for event type #{@zen.copy_type}")
    end

    def deep_archive_file_validation_error(file, bucket_name)
      logger.warn('Unable to validate file checksum; nil file') unless file.present?
      @zenodo_error_emails = APP_CONFIG['developer_email']
      return unless file.present? && @zenodo_error_emails.present?

      @file = file
      @bucket_name = bucket_name
      mail(to: @zenodo_error_emails,
           subject: "#{rails_env}Deep archive file checksum validation error")
    end

    def feedback_signup(message)
      @message = message
      @submission_error_emails = APP_CONFIG['developer_email'] || [@helpdesk_email]
      mail(to: @submission_error_emails, subject: "#{rails_env}User testing signup")
    end

    def voided_invoices(voided_identifier_list)
      return unless voided_identifier_list.present?

      @submission_error_emails = APP_CONFIG['developer_email'] || [@helpdesk_email]
      @identifiers = voided_identifier_list
      mail(to: @submission_error_emails,
           subject: "#{rails_env}Voided invoices need to be updated")
    end
  end
end
