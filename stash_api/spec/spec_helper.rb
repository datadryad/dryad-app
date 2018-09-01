require 'byebug'
require 'rails/all'
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

require 'stash_engine'
require 'stash_datacite'
require 'stash_api'

class ApplicationController < ActionController::Base
  # HACK: to get around the fact we're not running in an app
end

ENGINE_PATH = Gem::Specification.find_by_name('stash_api').gem_dir

# get hash of engine name and path for these
ENGINES = %w[stash_engine stash_datacite stash_api].map do |engine_name|
  engine_path = Gem::Specification.find_by_name(engine_name).gem_dir
  [engine_name, engine_path]
end.to_h

# This would be one way to get all paths where .rb files might live, not used now
my_models_path = "#{ENGINE_PATH}/app/models"
dirs_with_rb_files = Dir.glob("#{my_models_path}/**/*.rb").map { |i| File.dirname(i) }.uniq

$LOAD_PATH.unshift(*dirs_with_rb_files) # add dirs with .rb files to front of search path

$LOAD_PATH << '../lib'

# "autoload" these models in engines, pretending to be rails in a hacky way
ENGINES.each do |engine_name, engine_path|
  models_path = "#{engine_path}/app/models/#{engine_name}"
  $LOAD_PATH.unshift(models_path) if File.directory?(models_path)
  tmp = Dir.glob("#{models_path}/**/*.rb").sort
  tmp.sort! { |x, y| y.include?('/concerns/').to_s <=> x.include?('/concerns/').to_s } # sort concerns first
  tmp.each(&method(:require))
end

# require initializers for stash engine
stash_engine_path = ENGINES['stash_engine']
%w[
  hash_to_ostruct
  inflections
  repository
].each do |initializer|
  require "#{stash_engine_path}/config/initializers/#{initializer}.rb"
end

# some fun with licenses
LICENSES = YAML.load_file(File.expand_path('../config/licenses.yml', __FILE__)).with_indifferent_access

# TODO: stop needing to do this
module StashDatacite
  @@resource_class = 'StashEngine::Resource' # rubocop:disable Style/ClassVars
end

# TODO: stop needing to do these things
stash_datacite_path = ENGINES['stash_datacite']
require "#{stash_datacite_path}/config/initializers/patches.rb"
StashDatacite::ResourcePatch.associate_with_resource(StashEngine::Resource)

APP_CONFIG = OpenStruct.new(YAML.load_file(::File.expand_path('../config/app_config.yml', __FILE__))['test'])

# Note: Even if we're not doing any database work, ActiveRecord callbacks will still raise warnings
ActiveRecord::Base.raise_in_transactional_callbacks = true

# ------------------------------------------------------------
# Mocks

# require 'mocks/mock_repository'
