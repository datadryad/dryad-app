# ------------------------------------------------------------
# Simplecov

require 'simplecov' if ENV['COVERAGE']
require 'byebug'

# ------------------------------------------------------------
# Rspec configuration

RSpec.configure do |config|
  config.raise_errors_for_deprecations!
  config.mock_with :rspec
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
  tmp = Dir.glob("#{models_path}/**/*.rb").sort
  tmp.sort! { |x, y| y.include?('/concerns/').to_s <=> x.include?('/concerns/').to_s } # sort concerns first
  tmp.each(&method(:require))
end

stash_engine_path = ENGINES['stash_engine']
%w[
  hash_to_ostruct
  inflections
  repository
].each do |initializer|
  require "#{stash_engine_path}/config/initializers/#{initializer}.rb"
end

LICENSES = YAML.load_file(File.expand_path('config/licenses.yml', __dir__)).with_indifferent_access

# TODO: stop needing to do this
module StashDatacite
  @@resource_class = 'StashEngine::Resource' # rubocop:disable Style/ClassVars
end

# TODO: stop needing to do these things
stash_datacite_path = ENGINES['stash_datacite']
require "#{stash_datacite_path}/config/initializers/patches.rb"
StashDatacite::ResourcePatch.associate_with_resource(StashEngine::Resource)

require 'stash_datacite/author_patch'
StashDatacite::AuthorPatch.patch! unless StashEngine::Author.method_defined?(:affiliation)

require 'stash_datacite/user_patch'
StashDatacite::UserPatch.patch! unless StashEngine::User.method_defined?(:affiliation)
