# ------------------------------------------------------------
# SimpleCov setup

require 'simplecov'
require 'simplecov-console'

SimpleCov.minimum_coverage 100

SimpleCov.start do
  add_filter '/spec/'
  SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter[
      SimpleCov::Formatter::HTMLFormatter,
      SimpleCov::Formatter::Console,
  ]
end

# ------------------------------------------------------------
# Spec configuration

ENV['RAILS_ENV'] ||= 'test'

require File.expand_path('../dummy/config/environment.rb',  __FILE__)
require 'rspec/rails'
require 'factory_girl_rails'

# TODO: Separate fast/slow, DB/non-DB specs

# Load support files
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }
RSpec.configure do |config|
  config.raise_errors_for_deprecations!
  config.mock_with :rspec
  config.use_transactional_fixtures = true
  config.infer_base_class_for_anonymous_controllers = false
  config.order = 'random'
end

# ------------------------------------------------------------
# Stash::Harvester

require 'stash/harvester'
