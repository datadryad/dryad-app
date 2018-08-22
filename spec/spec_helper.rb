# ------------------------------------------------------------
# SimpleCov

if ENV['COVERAGE']
  require 'simplecov'
  SimpleCov.start 'rails'
end

# ------------------------------------------------------------
# Rspec configuration

RSpec.configure do |config|
  config.color = true
  config.tty = true
  config.formatter = :documentation
  config.raise_errors_for_deprecations!
  config.mock_with :rspec
end

# ------------------------------------------------------------
# Stash

STASH_ENGINE_PATH = Gem::Specification.find_by_name('stash_engine').gem_dir
STASH_DATACITE_PATH = Gem::Specification.find_by_name('stash_datacite').gem_dir
STASH_DISCOVERY_PATH = Gem::Specification.find_by_name('stash_discovery').gem_dir

require 'mocks/mock_repository.rb'
ActiveRecord::Migration.maintain_test_schema!
