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
ENV['RAILS_ENV'] = 'test'

require 'stash_engine'
require 'stash_datacite'

# TODO: Mock Rails.application.root and use stash_engine/config/initializers/licenses.rb
::LICENSES = YAML.load_file('config/licenses.yml').with_indifferent_access
# TODO: as above, but also move /config/initializers/app_config.rb from dash2 into stash_engine
::APP_CONFIG = OpenStruct.new(YAML.load_file('config/app_config.yml')['test'])

require 'active_record'
# Note: Even if we're not doing any database work, ActiveRecord callbacks will still raise warnings
ActiveRecord::Base.raise_in_transactional_callbacks = true

# TODO: simplify / standardize this
stash_engine_path = Gem::Specification.find_by_name('stash_engine').gem_dir
require "#{stash_engine_path}/config/initializers/hash_to_ostruct.rb"
require "#{stash_engine_path}/config/initializers/inflections.rb"
%w(
  app/models/stash_engine
  app/mailers
  app/mailers/stash_engine
  app/jobs/stash_engine
  lib/stash_engine
).each do |dir|
  Dir.glob("#{stash_engine_path}/#{dir}/**/*.rb").sort.each(&method(:require))
end

module StashDatacite
  @@resource_class = 'StashEngine::Resource' # rubocop:disable Style/ClassVars
end

stash_datacite_path = Gem::Specification.find_by_name('stash_datacite').gem_dir
%w(
  app/models/stash_datacite
  app/models/stash_datacite/resource
  lib/stash_datacite
  lib
).each do |dir|
  Dir.glob("#{stash_datacite_path}/#{dir}/**/*.rb").sort.each(&method(:require))
end

StashDatacite::ResourcePatch.associate_with_resource(StashEngine::Resource)

require 'util/resource_builder'
