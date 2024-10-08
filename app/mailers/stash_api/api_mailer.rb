module StashApi

  # Mails users about submissions
  class ApiMailer < ApplicationMailer

    def send_submit_request(resource, metadata)
      assign_variables(resource)
      return unless @user.present? && user_email(@user).present?

      status = resource.last_curation_activity.status
      @edit_url = "#{Rails.application.routes.url_helpers.root_url.chomp('/')}#{metadata[:editLink]}"

      mail(to: user_email(@user),
           subject: "#{rails_env}To be defined \"#{@resource.title}\"")

      update_activities(resource: resource, message: 'Send submit email requested through API. Submit ', status: status)
    end

  end
end
