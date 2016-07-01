module StashEngine
  class UserMailer < ApplicationMailer
    default from: APP_CONFIG['feedback_email_from'] # TODO: is this right?

    def upload_succeeded(resource, title)
      user = resource.user
      @to_address = to_address_list(user.email)
      @to_name = "#{user.first_name} #{user.last_name}" #TODO: something more i18n-friendly
      @title = title
      @identifier = resource.identifier
      # TODO: Get my_datasets URI
      @my_datasets_uri = my_datasets_uri
    end

    def upload_failed(resource, title, error)
      user = resource.user
      @to_address = to_address_list(user.email)
      @to_name = "#{user.first_name} #{user.last_name}" #TODO: something more i18n-friendly
      @title = title
      @identifier = resource.identifier
      # TODO: Get my_datasets URI
      @my_datasets_uri = my_datasets_uri
      @backtrace = to_backtrace(error)
      @admin_contact_address = to_address_list(admin_contact_address) #TODO: admin contact address
    end

    def error_report(resource, title, error)
      @to_address = to_address_list(APP_CONFIG['error_report_email']) # TODO: is this right?
      @user_name = "#{user.first_name} #{user.last_name}" #TODO: something more i18n-friendly
      @user_email = user.email #TODO: something more i18n-friendly
      @title = title
      @identifier = resource.identifier
      @backtrace = to_backtrace(error)
    end

    private

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
