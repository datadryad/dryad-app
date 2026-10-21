module StashApi

  # Mails users about submissions
  class ApiMailer < ApplicationMailer

    def send_submit_request(resource, metadata, author)
      @resource = resource
      @journal = StashEngine::Journal.find_by_issn(metadata[:relatedPublicationISSN])
      @user = author
      return unless @user.present? && user_email(@user).present?

      @user_name = user_name(@user)
      @helpdesk_email = APP_CONFIG['helpdesk_email']
      @edit_url = "#{Rails.application.routes.url_helpers.root_url.chomp('/')}#{metadata[:editLink]}"

      mail(to: user_email(@user),
           subject: "#{rails_env}Submit data for \"#{@resource.title.strip_tags}\"",
           bcc: @journal&.api_contacts)

      status = @resource.last_curation_activity.status
      update_activities(resource: resource, message: 'Send submit email requested through API. Submit ', status: status)
    end

    def send_scholar_one_submit_request(journal, metadata, author_metadata)
      @journal = journal
      email_address = author_metadata['authorPrimaryEmailAddress']
      return unless email_address.present?

      @title = metadata['submissionTitle'].html_safe
      @user_name = author_metadata['authorFullName']
      @manuscript_number = metadata['submissionId']

      @helpdesk_email = APP_CONFIG['helpdesk_email']
      @edit_url = new_resource_url

      mail(to: email_address,
           subject: "#{rails_env}Submit data for \"#{metadata['submissionTitle'].strip_tags}\"",
           bcc: @journal&.api_contacts)
    end
  end
end
