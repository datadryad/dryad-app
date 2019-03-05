module StashEngine

  # Mails users about submissions
  class UserMailer < ApplicationMailer
    # TODO: DRY these methods

    # add the formatted_date helper for view BAH -- doesn't seem to work
    # helper :formatted_date

    default from: "Dash Notifications <#{APP_CONFIG['feedback_email_from']}>",
            return_path: (APP_CONFIG['feedback_email_from']).to_s

    def error_report(resource, error)
      warn("Unable to report update error #{error}; nil resource") unless resource
      return unless resource

      init_from(resource)

      @backtrace = to_backtrace(error)

      to_address = address_list(APP_CONFIG['submission_error_email'])
      bcc_address = address_list(APP_CONFIG['submission_bc_emails'])
      mail(to: to_address, bcc: bcc_address,
           subject: "#{rails_env}Submitting dataset \"#{@title}\" (doi:#{@identifier_value}) failed")
    end

    def submission_succeeded(resource) # rubocop:disable Metrics/MethodLength
      warn('Unable to report successful submission; nil resource') unless resource
      return unless resource

      init_from(resource)
      @to_name = @user_name

      tenant = resource.tenant
      @host = tenant.full_domain

      @embargo_date = resource.publication_date unless resource.published?

      @to_name = @user_name
      to_address = address_list(@user_email)
      bcc_address = address_list([APP_CONFIG['submission_bc_emails']] + [tenant.campus_contacts])
      mail(to: to_address, bcc: bcc_address,
           subject: "#{rails_env}Dataset \"#{@title}\" (doi:#{@identifier_value}) submitted")
    end

    def submission_failed(resource, error) # rubocop:disable Metrics/MethodLength
      warn("Unable to report submission failure #{error}; nil resource") unless resource
      return unless resource

      init_from(resource)
      @to_name = @user_name

      user = resource.user
      tenant = resource.tenant
      @host = tenant.full_domain

      @backtrace = to_backtrace(error)

      to_address = address_list(user.email)
      bcc_address = address_list([APP_CONFIG['submission_error_email']].flatten + [APP_CONFIG['submission_bc_emails']].flatten)
      mail(to: to_address, bcc: bcc_address,
           subject: "#{rails_env}Submitting dataset \"#{@title}\" (doi:#{@identifier_value}) failed")
    end

    def orcid_invitation(orcid_invite)
      @invite = orcid_invite
      # need to calculate url here because url helpers work erratically in the mailer template itself
      @url = @invite.landing(StashEngine::Engine.routes.url_helpers.show_path(@invite.identifier.to_s, invitation: @invite.secret))
      mail(to: @invite.email,
           subject: "#{rails_env}Your dataset \"#{@invite.resource.title}\" has been published")
    end

    private

    def init_from(resource)
      user = resource.user
      @user_name = "#{user.first_name} #{user.last_name}"
      @user_email = user.email
      @title = resource.title
      @identifier_uri = resource.identifier_uri
      @identifier_value = resource.identifier_value
    end

    def address_list(addresses)
      addresses = [addresses] unless addresses.respond_to?(:join)
      addresses.flatten.reject(&:blank?).join(',')
    end

    def rails_env
      return "[#{Rails.env}] " unless Rails.env == 'production'
      ''
    end

    # TODO: look at Rails standard ways to report/format backtrace
    def to_backtrace(e)
      backtrace = e.respond_to?(:backtrace) && e.backtrace ? e.backtrace.join("\n") : ''
      "#{e.class}: #{e}\n#{backtrace}"
    end
  end
end
