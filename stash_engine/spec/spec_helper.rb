# ------------------------------------------------------------
# Simplecov

require 'simplecov' if ENV['COVERAGE']

# ------------------------------------------------------------
# Rspec configuration

RSpec.configure do |config|
  config.raise_errors_for_deprecations!
  config.mock_with :rspec
  config.full_backtrace = false
end

require_relative '../../spec_helpers/rspec_custom_matchers'

# ------------------------------------------------------------
# Rails

if (env = ENV['RAILS_ENV'])
  abort("Can't run tests in environment #{env}") if env != 'test'
else
  ENV['RAILS_ENV'] = 'test'
end

# ------------------------------------------------------------
# Stash

ENV['STASH_ENV'] = 'test'

require 'stash_engine'

LICENSES = YAML.load_file(File.expand_path('config/licenses.yml', __dir__)).with_indifferent_access
APP_CONFIG = OpenStruct.new(YAML.load_file(File.expand_path('config/app_config.yml', __dir__))['test'])
Settings = OpenStruct.new(YAML.load_file(File.expand_path('config/settings.yml', __dir__))['test'])

ENGINE_PATH = Gem::Specification.find_by_name('stash_engine').gem_dir

%W[
  #{ENGINE_PATH}/app/models/stash_engine/concerns
  #{ENGINE_PATH}/app/models/stash_engine
  #{ENGINE_PATH}/app/mailers
  #{ENGINE_PATH}/app/mailers/stash_engine
].each do |path|
  $LOAD_PATH.unshift(path) if File.directory?(path)
  Dir.glob("#{path}/**/*.rb").sort.each(&method(:require))
end

%w[
  hash_to_ostruct
  inflections
  repository
].each do |initializer|
  require "#{ENGINE_PATH}/config/initializers/#{initializer}.rb"
end

StashEngine.setup do |config|
  config.app = APP_CONFIG
end
# another hack on initializing because it sucks
StashEngine.app.payments = StashEngine.app.payments.to_ostruct

# Note: Even if we're not doing any database work, ActiveRecord callbacks will still raise warnings
ActiveRecord::Base.raise_in_transactional_callbacks = true

# ------------------------------------------------------------
# Mocks

require 'mocks/mock_repository'
require 'webmock/rspec'
