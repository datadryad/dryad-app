require 'rails_helper'
require 'capybara/dsl'
require 'capybara/rails'
require 'capybara/rspec'

# ############################################################
# Capybara config

Capybara.register_driver(:selenium) do |app|
  Capybara::Selenium::Driver.new(app, browser: :chrome)
end

Capybara.javascript_driver = :chrome

Capybara.configure do |config|
  config.default_max_wait_time = 10
  config.default_driver = :selenium
end

# ------------------------------------------------------------
# Solr config

require 'solr_helper'

SolrHelper.start

# ------------------------------------------------------------
# Additional RSpec configuration

RSpec.configure do |config|
  # Treat specs in features/ as feature specs
  config.infer_spec_type_from_file_location!

  config.after(:all) { SolrHelper.stop }
end
