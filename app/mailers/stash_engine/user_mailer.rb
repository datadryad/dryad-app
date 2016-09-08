module StashEngine
  # Mails users about submissions
  class UserMailer < ApplicationMailer
    # TODO: DRY these methods

    default from: "Dash Notifications <#{APP_CONFIG['feedback_email_from']}>",
            return_path: (APP_CONFIG['feedback_email_from']).to_s

    def create_succeeded(resource, title, request_host, request_port)
      user = resource.user
      @to_name = "#{user.first_name} #{user.last_name}"
      @title = title
      @identifier = identifier_for(resource)
      @request_host = request_host
      @request_port = request_port

      to_address = to_address_list(user.email)
      mail(to: to_address, subject: "Dataset submitted: #{@title}")
    end

    def create_failed(resource, title, request_host, request_port, error)
      user = resource.user
      @to_name = "#{user.first_name} #{user.last_name}"
      @title = title
      @identifier = identifier_for(resource)
      @backtrace = to_backtrace(error)
      tenant = user.tenant
      @contact_email = to_address_list(tenant.contact_email)
      @request_host = request_host
      @request_port = request_port

      to_address = to_address_list(user.email)
      mail(to: to_address, subject: "Dataset submission failure: #{@title}")
    end

    def update_succeeded(resource, title, request_host, request_port)
      user = resource.user
      @to_name = "#{user.first_name} #{user.last_name}"
      @title = title
      @identifier = identifier_for(resource)
      @request_host = request_host
      @request_port = request_port

      to_address = to_address_list(user.email)
      mail(to: to_address, subject: "Dataset \"#{@title}\" (#{@identifier}) updated")
    end

    def update_failed(resource, title, request_host, request_port, error)
      user = resource.user
      @to_name = "#{user.first_name} #{user.last_name}"
      @title = title
      @identifier = identifier_for(resource)
      @backtrace = to_backtrace(error)
      tenant = user.tenant
      @contact_email = to_address_list(tenant.contact_email)
      @request_host = request_host
      @request_port = request_port

      to_address = to_address_list(user.email)
      mail(to: to_address, subject: "Updating dataset \"#{@title}\" (#{@identifier}) failed")
    end

    def error_report(resource, title, error)
      user = resource.user
      @user_name = "#{user.first_name} #{user.last_name}"
      @user_email = user.email
      @title = title
      @identifier = identifier_for(resource)
      @backtrace = to_backtrace(error)

      to_address = to_address_list(APP_CONFIG['feedback_email_to'])
      mail(to: to_address, subject: "Submitting dataset \"#{@title}\" (#{@identifier}) failed")
    end

    private

    def identifier_for(resource)
      return unless resource
      # TODO: add something like 'delegate :identifier_value' to Resource, cf. http://devblog.avdi.org/2011/07/05/demeter-its-not-just-a-good-idea-its-the-law/
      # TODO: and make sure it works even if we're not talking Datacite
      resource.identifier.try(:identifier)
    end

    def to_address_list(addresses)
      addresses = [addresses] unless addresses.respond_to?(:join)
      addresses.join(',')
    end

    # TODO: look at Rails standard ways to report/format backtrace
    def to_backtrace(e)
      backtrace = e.respond_to?(:backtrace) ? e.backtrace.join("\n") : ''
      "#{e.class}: #{e}\n#{backtrace}"
    end
  end
end
