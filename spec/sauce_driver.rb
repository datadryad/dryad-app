require "selenium/webdriver"

module SauceDriver
  class << self

    def username
      ENV['SAUCE_USERNAME']
    end

    def access_key
      ENV['SAUCE_ACCESS_KEY']
    end

    def authentication
      "#{username}:#{access_key}"
    end

    def sauce_server
      'ondemand.saucelabs.com'
    end

    def sauce_port
      80
    end

    def endpoint
      "http://#{authentication}@#{sauce_server}:#{sauce_port}/wd/hub"
    end

    def prerun
      {
           'executable':'https://raw.githubusercontent.com/CDLUC3/stash_datacite/development/spec/features/support/copy_image_to_sauce.sh',
           'background': 'false'
      }
    end
  end
end