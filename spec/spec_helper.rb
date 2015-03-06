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

