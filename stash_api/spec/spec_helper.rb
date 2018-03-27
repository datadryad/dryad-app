# ------------------------------------------------------------
# Rspec configuration

RSpec.configure do |config|
  config.raise_errors_for_deprecations!
  config.mock_with :rspec
end

# require 'rspec_custom_matchers'

# ------------------------------------------------------------
# Rails

if (env = ENV['RAILS_ENV'])
  abort("Can't run tests in environment #{env}") if env != 'test'
else
  ENV['RAILS_ENV'] = 'test'
end
