# Base class for mailers
class ApplicationMailer < ActionMailer::Base
  default from: APP_CONFIG['feedback_email_from'] || APP_CONFIG['contact_email'].last
  layout 'mailer'

  private

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
    @title = resource.title&.strip_tags
    @user = resource.submitter || resource.owner_author
    @user_name = user_name(@user)
    @helpdesk_email = APP_CONFIG['helpdesk_email'] || 'help@datadryad.org'
    @bcc_emails = APP_CONFIG['submission_bc_emails'] || [@helpdesk_email]
    @submission_error_emails = APP_CONFIG['submission_error_email'] || [@helpdesk_email]
    @page_error_emails = APP_CONFIG['page_error_email'] || [@helpdesk_email]
  end

  def update_activities(resource:, message:, status:, journal: false)
    recipient = journal ? 'journal' : 'author'
    note = "#{message} notification sent to #{recipient}"
    CurationService.new(
      resource: resource,
      user_id: 0, # system user
      note: note,
      status: status
    ).process
  end

  def rails_env
    return "[#{Rails.env}] " unless Rails.env.include?('production')

    ''
  end
end
