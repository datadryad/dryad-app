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

::LICENSES = YAML.load_file('config/licenses.yml')

# TODO: simplify / standardize this
stash_engine_path = Gem::Specification.find_by_name('stash_engine').gem_dir
require "#{stash_engine_path}/config/initializers/hash_to_ostruct.rb"
Dir.glob("#{stash_engine_path}/app/models/stash_engine/**/*.rb").sort.each(&method(:require))
Dir.glob("#{stash_engine_path}/app/jobs/stash_engine/**/*.rb").sort.each(&method(:require))
Dir.glob("#{stash_engine_path}/lib/stash_engine/**/*.rb").sort.each(&method(:require))

