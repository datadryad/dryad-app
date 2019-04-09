require 'action_mailer'

# A mailer for the applicastion, is this one used?
class ApplicationMailer < ActionMailer::Base
  default from: APP_CONFIG['feedback_email_from'] || APP_CONFIG['contact_email'].last
  layout 'mailer'
end
