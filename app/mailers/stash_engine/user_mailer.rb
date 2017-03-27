module StashEngine

  # Mails users about submissions
  class UserMailer < ApplicationMailer
    # TODO: DRY these methods

    default from: "Dash Notifications <#{APP_CONFIG['feedback_email_from']}>",
      return_path: (APP_CONFIG['feedback_email_from']).to_s

    def error_report(resource, error)
      warn("Unable to report update error #{error}; nil resource") unless resource
      return unless resource

      user = resource.user
      @user_name = "#{user.first_name} #{user.last_name}"
      @user_email = user.email
      @title = resource.primary_title
      @identifier_uri = resource.identifier_uri
      @identifier_value = resource.identifier_value
      @backtrace = to_backtrace(error)

      to_address = to_address_list(APP_CONFIG['support_team_email'])
      tenant = user.tenant
      bcc_address = to_address_list(tenant.manager_email)
      mail(to: to_address, bcc: bcc_address,
           subject: "#{rails_env}Submitting dataset \"#{@title}\" (doi:#{@identifier_value}) failed")
    end

    def submission_succeeded(resource)
      warn('Unable to report successful submission; nil resource') unless resource
      return unless resource

      user = resource.user
      @to_name = "#{user.first_name} #{user.last_name}"
      @title = resource.primary_title
      @identifier_uri = resource.identifier_uri
      @identifier_value = resource.identifier_value

      tenant = user.tenant
      @host = tenant.full_domain

      to_address = to_address_list(user.email)
      bcc_address = to_address_list(tenant.manager_email)
      mail(to: to_address, bcc: bcc_address,
           subject: "#{rails_env}Dataset \"#{@title}\" (doi:#{@identifier_value}) submitted")
    end

    def submission_failed(resource, error)
      warn("Unable to report submission failure #{error}; nil resource") unless resource
      return unless resource

      user = resource.user
      @to_name = "#{user.first_name} #{user.last_name}"
      @title = resource.primary_title
      @identifier_uri = resource.identifier_uri
      @identifier_value = resource.identifier_value

      tenant = user.tenant
      @host = tenant.full_domain

      @backtrace = to_backtrace(error)

      to_address = to_address_list(user.email)
      bcc_address = to_address_list([APP_CONFIG['support_team_email']].flatten + [tenant.manager_email].flatten)
      mail(to: to_address, bcc: bcc_address,
           subject: "#{rails_env}Submitting dataset \"#{@title}\" (doi:#{@identifier_value}) failed")
    end

    private

    def to_address_list(addresses)
      addresses = [addresses] unless addresses.respond_to?(:join)
      addresses.reject { |i| i.nil? || i.blank? }.join(',')
    end

    def rails_env
      return "[#{Rails.env}] " unless Rails.env == 'production'
      ''
    end

    # TODO: look at Rails standard ways to report/format backtrace
    def to_backtrace(e)
      backtrace = (e.respond_to?(:backtrace) && e.backtrace) ? e.backtrace.join("\n") : ''
      "#{e.class}: #{e}\n#{backtrace}"
    end
  end
end
