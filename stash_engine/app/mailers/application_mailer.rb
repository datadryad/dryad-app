require 'action_mailer'

# A mailer for the applicastion, is this one used?
class ApplicationMailer < ActionMailer::Base
  default from: APP_CONFIG['feedback_email_from'] || APP_CONFIG['contact_email'].last
  layout 'mailer'

  # rubocop:disable Style/NestedTernaryOperator
  def user_email(user)
    user.present? ? (user.respond_to?(:author_email) ? user.author_email : user.email) : nil
  end

  def user_name(user)
    user.present? ? (user.respond_to?(:author_standard_name) ? user.author_standard_name : user.name) : nil
  end
  # rubocop:enable Style/NestedTernaryOperator

  def assign_variables(resource)
    @resource = resource
    @helpdesk_email = APP_CONFIG['helpdesk_email'] || 'help@datadryad.org'
    @bcc_emails = APP_CONFIG['submission_bc_emails'] || [@helpdesk_email]
    @submission_error_emails = APP_CONFIG['submission_error_email'] || [@helpdesk_email]
    @page_error_emails = APP_CONFIG['page_error_email'] || [@helpdesk_email]
  end

  def rails_env
    return "[#{Rails.env}]" unless Rails.env == 'production'
    ''
  end

end
