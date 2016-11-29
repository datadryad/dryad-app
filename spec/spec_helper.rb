# ------------------------------------------------------------
# Rspec configuration

RSpec.configure do |config|
  config.raise_errors_for_deprecations!
  config.mock_with :rspec
end

require 'rspec_custom_matchers'

# ------------------------------------------------------------
# Stash

ENV['STASH_ENV'] = 'test'
ENV['RAILS_ENV'] = 'test'

require 'stash_engine'

# TODO: simplify / standardize this
stash_engine_path = Gem::Specification.find_by_name('stash_engine').gem_dir

if ENV['COVERAGE']
  require 'simplecov'
  require 'simplecov-console'

  class StashEngineFilter < SimpleCov::Filter
    def matches?(source_file)
      stash_engine_path = filter_argument
      path = source_file.filename
      return false if path =~ /^#{stash_engine_path}/
      return false if path =~ /^#{SimpleCov.root}/
      true
    end
  end

  # Hack for SimpleCov #5 https://github.com/chetan/simplecov-console/issues/5
  Module::ROOT = Dir.pwd
  SimpleCov::Formatter::Console::ROOT = Dir.pwd

  # SimpleCov.command_name 'spec:lib'
  SimpleCov.minimum_coverage 100

  SimpleCov.command_name 'spec:unit' # TODO: Figure out test suite merging
  SimpleCov.start do
    filters.clear
    add_filter '/spec/'
    add_filter StashEngineFilter.new(stash_engine_path)
    SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter[
        SimpleCov::Formatter::HTMLFormatter,
        SimpleCov::Formatter::Console,
    ]
  end
end

require "#{stash_engine_path}/config/initializers/hash_to_ostruct.rb"

::LICENSES = YAML.load_file('config/licenses.yml')
::APP_CONFIG = OpenStruct.new(YAML.load_file('config/app_config.yml')['test'])

%w(
  app/models/stash_engine
  app/mailers
  app/mailers/stash_engine
  app/jobs/stash_engine
  lib/stash_engine
).each do |dir|
  Dir.glob("#{stash_engine_path}/#{dir}/**/*.rb").sort.each(&method(:require))
end
