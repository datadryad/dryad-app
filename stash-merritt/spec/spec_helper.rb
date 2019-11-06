# ------------------------------------------------------------
# SimpleCov setup

if ENV['COVERAGE']
  require 'simplecov'
  require 'simplecov-console'

  SimpleCov.minimum_coverage 100
  SimpleCov.start do
    add_filter '/spec/'
    SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter.new [
      SimpleCov::Formatter::HTMLFormatter,
      SimpleCov::Formatter::Console
    ]
  end
end

# ------------------------------------------------------------
# Rspec configuration

RSpec.configure do |config|
  config.raise_errors_for_deprecations!
  config.mock_with :rspec
end

require_relative '../../spec_helpers/rspec_custom_matchers'

# ------------------------------------------------------------
# ActiveRecord

require 'active_record'
# Note: Even if we're not doing any database work, ActiveRecord callbacks will still raise warnings
ActiveRecord::Base.raise_in_transactional_callbacks = true

# ------------------------------------------------------------
# StashEngine

ENV['STASH_ENV'] = 'test'
ENV['RAILS_ENV'] = 'test'

::LICENSES = YAML.load_file('spec/config/licenses.yml').with_indifferent_access
::APP_CONFIG = OpenStruct.new(YAML.load_file('spec/config/app_config.yml')['test'])

stash_engine_path = Gem::Specification.find_by_name('stash_engine').gem_dir
require "#{stash_engine_path}/config/initializers/hash_to_ostruct.rb"
require "#{stash_engine_path}/config/initializers/inflections.rb"

require 'stash_engine'

%w[
  app/models/stash_engine
  app/mailers
  app/mailers/stash_engine
  app/jobs/stash_engine
  lib/stash_engine
].each do |dir|
  tmp = Dir.glob("#{stash_engine_path}/#{dir}/**/*.rb").sort
  tmp.sort! { |x, y| y.include?('/concerns/').to_s <=> x.include?('/concerns/').to_s } # sort concerns first
  tmp.each(&method(:require))
end

$LOAD_PATH.unshift("#{stash_engine_path}/app/models")

# ------------------------------------------------------------
# StashDatacite

module StashDatacite
  @@resource_class = 'StashEngine::Resource' # rubocop:disable Style/ClassVars
end

require 'stash_datacite'

# TODO: do we need all of these?
stash_datacite_path = Gem::Specification.find_by_name('stash_datacite').gem_dir
%w[
  app/models/stash_datacite
  app/models/stash_datacite/resource
  lib/stash_datacite
  lib
].each do |dir|
  Dir.glob("#{stash_datacite_path}/#{dir}/**/*.rb").sort.each(&method(:require))
end
StashDatacite::ResourcePatch.associate_with_resource(StashEngine::Resource)
require "#{stash_datacite_path}/config/initializers/patches.rb"

require 'util/resource_builder'

# ------------------------------------------------------------
# Stash::Merritt

require 'stash/merritt'
