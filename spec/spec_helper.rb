require 'simplecov'
require 'simplecov-console'

SimpleCov.minimum_coverage 100

SimpleCov.start do
  SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter[
      SimpleCov::Formatter::HTMLFormatter,
      SimpleCov::Formatter::Console,
  ]
end

require 'rspec'
require 'dash2/harvester'

RSpec.configure(&:raise_errors_for_deprecations!)
