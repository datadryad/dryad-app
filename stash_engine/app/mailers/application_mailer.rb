require 'action_mailer'

# A mailer for the applicastion, is this one used?
class ApplicationMailer < ActionMailer::Base
  @helpdesk_email = APP_CONFIG['helpdesk_email'] || 'help@datadryad.org'

  @from_email = APP_CONFIG['feedback_email_from'] || @helpdesk_email
  @bcc_emails = APP_CONFIG['submission_bc_emails'] || [@helpdesk_email]
  @submission_error_emails = APP_CONFIG['submission_error_email'] || [@helpdesk_email]
  @page_error_emails = APP_CONFIG['page_error_email'] || [@helpdesk_email]

  @dryad_url = 'http://www.datadryad.org'

  default from: @from_email

  layout 'mailer'
end
