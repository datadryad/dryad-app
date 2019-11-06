# ------------------------------------------------------------
# SimpleCov setup

if ENV['COVERAGE']
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
end

# ------------------------------------------------------------
# Rspec configuration

require 'rspec'

RSpec.configure do |config|
  config.raise_errors_for_deprecations!
  config.mock_with :rspec
end

require_relative '../../spec_helpers/rspec_custom_matchers'

# ------------------------------------------------------------
# Code under test

require 'stash/sword'
