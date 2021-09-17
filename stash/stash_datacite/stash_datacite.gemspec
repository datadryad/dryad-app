$LOAD_PATH.push File.expand_path('lib', __dir__)

# Maintain your gem's version:
require 'stash_datacite/version'

# The following URL clarifies how gemspecs work vs the normal Gemfiles and that gemspecs generally should be more generous with
# version dependencies if released for public use separately.  Some doesn't apply since our gems are usually just a
# way of dividing our application. We may or may not want to check in Gemfile.lock for our private gems since app-specific
# unlike a public gem/engine that is expected to be used in a variety of outside applications.
# https://yehudakatz.com/2010/12/16/clarifying-the-roles-of-the-gemspec-and-gemfile/

# Development dependencies become really somewhat useless or work at cross-purposes in some Ruby/Rails environments
# and you can't really  depend on them to fulfil your dependencies correctly for testing/development environments. See this thread
# where a developer finds them less than useful and very confusing for modern rails environments, yet the maintainers
# don't want to touch the problems, surprises and confusion about development dependencies.
# https://github.com/rubygems/rubygems/issues/1104

# But in any case, the takeaway here is that it's probably better for us to put these requirements into test/development groups
# using the Gemfile for our private gems and engines so the the gem requirements actually get satisfied correctly on
# new software installs intended for development or testing because add_development_dependency is weak sauce
# for our uses.

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = 'stash_datacite'
  s.version     = StashDatacite::VERSION
  s.authors     = ['sfisher']
  s.email       = ['scott.fisher@ucop.edu']
  s.homepage    = 'https://github.com/CDL-Dryad/stash'
  s.summary     = 'Engine for working with the DataCite schema in Stash.'
  s.description = 'An engine for working with the DataCite schema in Stash.'
  s.license     = 'MIT'

  s.required_ruby_version = '~> 2.6.6'

  s.files = Dir['{app,config,db,lib}/**/*', 'MIT-LICENSE', 'Rakefile', 'README.rdoc']
  s.test_files = Dir['test/**/*']

  s.add_dependency 'amatch', '~> 0.4.0'
  s.add_dependency 'kaminari', '~> 1.2.1'
  s.add_dependency 'leaflet-rails', '~> 1.7.0'
  s.add_dependency 'loofah', '~> 2.12.0'
  s.add_dependency 'mysql2', '~> 0.5.3'
  s.add_dependency 'rails', '~> 5.2.6'
  s.add_dependency 'responders', '~> 3.0.1'
  s.add_dependency 'rubyzip', '~> 2.3.2'
  s.add_dependency 'serrano', '~> 1.0.0'
  s.add_dependency 'sync', '~> 0.5.0'
  s.add_dependency 'tins', '~> 1.29.1'

  # s.add_dependency 'datacite-mapping'
  # s.add_dependency 'stash_discovery'
  # s.add_dependency 'stash_engine'
  # s.add_dependency 'stash-wrapper'
  #
  # s.add_development_dependency 'colorize'
  # s.add_development_dependency 'database_cleaner'
  # s.add_development_dependency 'diffy'
  # s.add_development_dependency 'equivalent-xml'
  # s.add_development_dependency 'mysql2'
  # s.add_development_dependency 'nokogiri'
  # s.add_development_dependency 'rubocop'
  # s.add_development_dependency 'simplecov'
  # s.add_development_dependency 'simplecov-console'
  # s.add_development_dependency 'webmock'
end
