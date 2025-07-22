module StashApi

  # Mails users about submissions
  class ApiMailer < ApplicationMailer

    def send_submit_request(resource, metadata)
      @resource = resource
      @user = @resource.authors.where.not(author_email: [nil, '']).first
      return unless @user.present? && user_email(@user).present?

      @user_name = user_name(@user)
      @helpdesk_email = APP_CONFIG['helpdesk_email'] || 'help@datadryad.org'
      @edit_url = "#{Rails.application.routes.url_helpers.root_url.chomp('/')}#{metadata[:editLink]}"

      mail(to: user_email(@user),
           subject: "#{rails_env}Submit data for \"#{@resource.title}\"")

      status = @resource.last_curation_activity.status
      update_activities(resource: resource, message: 'Send submit email requested through API. Submit ', status: status)
    end

  end
end
