# ------------------------------------------------------------
# Simplecov

require 'simplecov' if ENV['COVERAGE']

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

require 'stash_engine'
require 'stash_datacite'

class ApplicationController < ActionController::Base
  # HACK: to get around the fact we're not running in an app
end

ENGINES = %w[stash_engine stash_datacite stash_discovery].map do |engine_name|
  engine_path = Gem::Specification.find_by_name(engine_name).gem_dir
  [engine_name, engine_path]
end.to_h

ENGINES.each do |engine_name, engine_path|
  models_path = "#{engine_path}/app/models/#{engine_name}"
  $LOAD_PATH.unshift(models_path) if File.directory?(models_path)
  Dir.glob("#{models_path}/**/*.rb").sort.each(&method(:require))
end

# ------------------------------------------------------------
# Misc. utils

Dir.glob(File.expand_path('../util/*.rb', __FILE__)).sort.each(&method(:require))
