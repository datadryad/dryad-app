# frozen_string_literal: true

module StashEngine
  module StatusDashboard

    class ShibbolethService < DependencyCheckerService
      URL = "#{ROOT_URL}/cgi-bin/PrintShibInfo.pl".freeze
      ORG_XPATH = "//select[@id='userIdPSelection']/option[text()='ACS Schools']"
      ORG_LINK = 'https://idp.acs-schools.com/openathens'

      def ping_dependency
        super

        cmd = ['curl', '-s', '-o', '/dev/null', '-w', '%{http_code}', '-I', URL]
        stdout, _stderr, _status = Open3.capture3(*cmd)

        if stdout != '302'
          record_status(online: false, message: 'Page does not redirect to proper link!')
          return false
        end

        cmd = ['curl', '-s', '-L', URL]
        stdout, stderr, status = Open3.capture3(*cmd)

        err_message = ''
        if status.success?
          document = Nokogiri::HTML(stdout)

          option = document.at_xpath(ORG_XPATH)
          err_message = 'Could not find configured organization!' if !option || option['value'] != ORG_LINK
        else
          err_message = "Failed loading organizations list page: #{stderr}"
        end

        if err_message.present?
          record_status(online: false, message: err_message)
        else
          record_status(online: true, message: 'Shibboleth login successful')
        end
      rescue StandardError => e
        record_status(online: false, message: e.to_s)
        false
      end

    end

  end
end
