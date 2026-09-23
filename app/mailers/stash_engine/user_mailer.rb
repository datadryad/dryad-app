module StashEngine
  class UserMailer < ApplicationMailer
    # Called from the LandingController when an update happens
    def orcid_invitation(orcid_invite)
      # need to calculate url here because url helpers work erratically in the mailer template itself
      path = Rails.application.routes.url_helpers.show_path(orcid_invite.identifier.to_s, invitation: orcid_invite.secret)
      @url = orcid_invite.landing(path)
      @resource = orcid_invite.resource
      @helpdesk_email = APP_CONFIG['helpdesk_email']
      @user_name = "#{orcid_invite.first_name} #{orcid_invite.last_name}"
      mail(to: orcid_invite.email,
           subject: "#{rails_env}Dryad Submission \"#{@resource.title.strip_tags}\"")
    end

    def search_subscription(search, json)
      @search = search
      @json = json
      @user_name = user_name(search.user)
      mail(to: user_email(search.user), subject: "#{rails_env}New Dryad search results") { |fmt| fmt.html { render layout: 'subscription' } }
    end

    def check_email(email_token)
      return unless email_token.user&.email&.present?

      @helpdesk_email = APP_CONFIG['helpdesk_email']
      @user_name = user_name(email_token.user)
      @token = email_token.token
      mail(to: user_email(email_token.user), subject: "#{rails_env}Your Dryad account code")
    end

    def check_tenant_email(email_token)
      return if email_token.tenant&.authentication&.email_domain.blank?
      return unless email_token.user&.email&.end_with?(email_token.tenant.authentication.email_domain)

      @helpdesk_email = APP_CONFIG['helpdesk_email']
      @user_name = user_name(email_token.user)
      @tenant_name = email_token.tenant&.long_name
      @token = email_token.token
      mail(to: user_email(email_token.user), subject: "#{rails_env}Your Dryad account code")
    end

    def invite_author(edit_code)
      return unless edit_code.author.author_email.present? && edit_code&.edit_code&.present?

      @helpdesk_email = APP_CONFIG['helpdesk_email']
      @user_name = user_name(edit_code.author)
      @resource = edit_code.author.resource
      @role = edit_code.role
      @url = "#{ROOT_URL}#{Rails.application.routes.url_helpers.accept_invite_path(edit_code: edit_code.edit_code)}"
      mail(to: user_email(edit_code.author), subject: "#{rails_env}Invitation to edit submission \"#{@resource.title&.strip_tags}\"")
    end

    def invite_user(user, role)
      return unless user.email&.present? && role.role&.present?

      @helpdesk_email = APP_CONFIG['helpdesk_email']
      @user_name = user_name(user)
      @resource = role.role_object
      @role = role.role
      mail(to: user_email(user), subject: "#{rails_env}Invitation to edit submission \"#{@resource.title&.strip_tags}\"")
    end
  end
end
