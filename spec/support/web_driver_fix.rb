# @TODO Remove this Monkey Patch after issue is resolved with running Chrome 74 in
#       headless mode: https://github.com/teamcapybara/capybara/issues/2181
module Selenium
  module WebDriver
    class Options
      # capybara/rspec installs a RSpec callback that runs after each test and resets
      # the session - part of which is deleting all cookies. However the call to Chrome
      # Webdriver to delete all cookies in Chrome 74 hangs when run in headless mode
      # (the reasons for which are still unknown).
      #
      # Fortunately, the call to set a cookie is still functioning and we can rely
      # on expired cookies being cleared by Chrome, so we iterate over all current
      # cookies and set their expiry date to some time in the past - effectively
      # deleting them.
      def delete_all_cookies
        all_cookies.each do |cookie|
          add_cookie(name: cookie[:name], value: '', expires: Time.now - 1.second)
        end
      end
    end
  end
end