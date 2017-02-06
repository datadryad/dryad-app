require "selenium/webdriver"

module SauceDriver
  class << self
    def sauce_endpoint
      "http://cdluc3:4eb42a92-0fc6-43d5-9494-4d52a50a066f@ondemand.saucelabs.com:80/wd/hub"
    end

    def caps
      caps = {
        :platform => "Mac OS X 10.10",
        :browserName => "Chrome",
        :version => "55.0"
      }
    end

    def new_driver
      Selenium::WebDriver.for :remote, :url => sauce_endpoint, :desired_capabilities => caps
    end
  end
end