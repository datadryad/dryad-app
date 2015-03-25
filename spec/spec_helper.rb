require 'simplecov'
require 'simplecov-console'

SimpleCov.start do
  SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter[
      SimpleCov::Formatter::HTMLFormatter,
      SimpleCov::Formatter::Console,
  ]
end

require 'rspec'
require 'dash2/harvester'

RSpec.configure do |config|
  config.raise_errors_for_deprecations!
end
