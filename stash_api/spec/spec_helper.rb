require 'byebug'
# ------------------------------------------------------------
# Rspec configuration

RSpec.configure do |config|
  config.raise_errors_for_deprecations!
  config.mock_with :rspec
end

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

require 'stash_api'

APP_CONFIG = OpenStruct.new(YAML.load_file(File.expand_path('../config/app_config.yml', __FILE__))['test'])

ENGINE_PATH = Gem::Specification.find_by_name('stash_api').gem_dir

# need to fix this so it loads first before other things inheriting from it
%W[
  #{ENGINE_PATH}/app/models/stash_api
  #{ENGINE_PATH}/app/models/stash_api/version
  #{ENGINE_PATH}/app/models/stash_api/version/metadata
].each do |path|
  $LOAD_PATH.unshift(path) if File.directory?(path)
  Dir.glob("#{path}/**/*.rb").sort.each(&method(:require))
end

%w[
  doorkeeper
  monkey_patches
].each do |initializer|
  require "#{ENGINE_PATH}/config/initializers/#{initializer}.rb"
end

# Note: Even if we're not doing any database work, ActiveRecord callbacks will still raise warnings
ActiveRecord::Base.raise_in_transactional_callbacks = true

# ------------------------------------------------------------
# Mocks

# require 'mocks/mock_repository'

