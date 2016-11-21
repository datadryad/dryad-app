require 'selenium-webdriver'
require 'page-object'
require 'page-object/page_factory'
require 'capybara/rails'

World(PageObject::PageFactory)
Before do
  @browser = Selenium::WebDriver.for :firefox
end

After do
  @browser.close
end