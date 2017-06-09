require 'selenium/webdriver'

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

    def environment_capabilities
      browser = ENV['SAUCE_BROWSER']
      version = ENV['SAUCE_VERSION']
      platform = 'Mac OS X 10.10'
      tunnel_identifier = ENV['TRAVIS_JOB_NUMBER']
      # prerun = 'https://raw.githubusercontent.com/CDLUC3/stash_datacite/development/spec/features/support/copy_image_to_sauce.sh'

      if browser && version && platform && tunnel_identifier
        return {
          browserName: browser,
          version: version,
          platform: platform,
          tunnel_identifier: tunnel_identifier
          # :prerun => prerun
        }
      end

      nil
    end

    def desired_caps
      environment_capabilities
    end
  end
end
