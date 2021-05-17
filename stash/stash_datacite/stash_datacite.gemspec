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

  s.add_dependency 'amatch', '~> 0.4.0' # Matching Resource titles against Crossref results
  s.add_dependency 'kaminari', '~> 1.2'
  s.add_dependency 'leaflet-rails', '~> 1.3'
  s.add_dependency 'loofah', '~> 2.7'
  s.add_dependency 'mysql2', '~> 0.4'
  s.add_dependency 'rails', '~> 5.2'
  s.add_dependency 'responders', '~> 3.0', '>= 3.0.1'
  s.add_dependency 'rubyzip', '~> 2.3'
  s.add_dependency 'serrano', '~> 0.6' # for CrossRef API
  s.add_dependency 'sync', '~> 0.5'
  s.add_dependency 'tins', '~> 1.25'

  s.add_dependency 'datacite-mapping', '~> 0.4.0'
  s.add_dependency 'stash_discovery', '~> 0.0'
  s.add_dependency 'stash_engine', '~> 0.0'
  s.add_dependency 'stash-wrapper', '~> 0.0'

  s.add_development_dependency 'colorize', '~> 0.8'
  s.add_development_dependency 'database_cleaner', '~> 1.8', '>= 1.8.5'
  s.add_development_dependency 'diffy', '~> 3.1'
  s.add_development_dependency 'equivalent-xml', '~> 0.6', '>= 0.6.0'
  s.add_development_dependency 'mysql2', '~> 0.4'
  s.add_development_dependency 'nokogiri', '~> 1.8'
  s.add_development_dependency 'rubocop', '~> 0.57.2'
  s.add_development_dependency 'simplecov', '~> 0.14'
  s.add_development_dependency 'simplecov-console', '~> 0.4'
  s.add_development_dependency 'webmock', '~> 3.0'
end
