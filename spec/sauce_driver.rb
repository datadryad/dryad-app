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

    def environment_capabilities
      browser = ENV['SAUCE_BROWSER']
      version = ENV['SAUCE_VERSION']
      platform = "Mac OS X 10.10"
      tunnel_identifier = ENV['TRAVIS_JOB_NUMBER']

      if browser && version && platform
        return {
          :browserName => browser,
          :version => version,
          :platform => platform,
          :tunnel_identifier => tunnel_identifier
        }
      end

      return nil
    end

    def desired_caps
      environment_capabilities
    end

    def webdriver_config
      {
        :browser => :remote,
        :url => endpoint,
        :desired_capabilities => desired_caps
      }
    end
  end
end