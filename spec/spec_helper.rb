# ------------------------------------------------------------
# SimpleCov setup

require 'simplecov'
require 'simplecov-console'

SimpleCov.minimum_coverage 100

SimpleCov.start do
  add_filter "/spec/"
  SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter[
      SimpleCov::Formatter::HTMLFormatter,
      SimpleCov::Formatter::Console,
  ]
end

# ------------------------------------------------------------
# RSpec configuration

RSpec.configure(&:raise_errors_for_deprecations!)

require 'rspec'

# ------------------------------------------------------------
# Stash::Harvester

require 'stash/harvester'

