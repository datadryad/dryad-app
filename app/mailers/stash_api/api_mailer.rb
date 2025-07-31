module StashApi

  # Mails users about submissions
  class ApiMailer < ApplicationMailer

    def send_submit_request(resource, metadata, author)
      @resource = resource
      @journal = StashEngine::Journal.find_by_issn(metadata[:relatedPublicationISSN])
      @user = author
      return unless @user.present? && user_email(@user).present?

      @user_name = user_name(@user)
      @helpdesk_email = APP_CONFIG['helpdesk_email'] || 'help@datadryad.org'
      @edit_url = "#{Rails.application.routes.url_helpers.root_url.chomp('/')}#{metadata[:editLink]}"

      mail(to: user_email(@user),
           subject: "#{rails_env}Submit data for \"#{@resource.title}\"",
           bcc: @journal&.api_contacts)

      status = @resource.last_curation_activity.status
      update_activities(resource: resource, message: 'Send submit email requested through API. Submit ', status: status)
    end

  end
end
