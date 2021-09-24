$LOAD_PATH.push File.expand_path('lib', __dir__)

# Maintain your gem's version:
require 'stash_discovery/version'

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
# travis or on new software installs intended for development or testing because add_development_dependency is weak sauce
# for our uses.

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = 'stash_discovery'
  s.version     = StashDiscovery::VERSION
  s.authors     = ['David Moles']
  s.email       = ['david.moles@ucop.edu']
  s.homepage    = 'https://github.com/CDL-Dryad/stash'
  s.summary     = 'The discovery module for Stash'
  s.description = 'GeoBlacklight-based discovery module for Stash'
  s.license     = 'MIT'

  s.required_ruby_version = '~> 2.6.6'

  s.files = Dir['{app,config,db,lib}/**/*', 'MIT-LICENSE', 'Rakefile', 'README.rdoc']
  s.test_files = Dir['test/**/*']

  # s.add_dependency 'activestorage'
  s.add_dependency 'blacklight', '~> 7.19.2' # not really sure this needs to be put in separately since geoblacklight pulls it in, probably
  s.add_dependency 'bootstrap', '~> 4.0' # because there is a generator that adds this
  # s.add_dependency 'bootstrap-sass'
  # s.add_dependency 'config'
  s.add_dependency 'devise'
  s.add_dependency 'devise-guests', '~> 0.6'
  # s.add_dependency 'ffi'
  s.add_dependency 'geoblacklight', '~> 3.4.0'
  s.add_dependency 'jquery-rails'
  # s.add_dependency 'net-http-persistent', '~> 2.0'
  # s.add_dependency 'popper_js'
  # s.add_dependency 'rails'
  # s.add_dependency 'rails-ujs'
  s.add_dependency 'rsolr', '>= 1.0', '< 3'
  # s.add_dependency 'sass-rails', '>= 3.2'
  s.add_dependency 'solr_wrapper', '~> 3.1.2'
  # s.add_dependency 'turbolinks'
  s.add_dependency 'twitter-typeahead-rails', '0.11.1.pre.corejavascript' # this is in a generator to install blacklight

  # extra deps from generated GeoBlacklight app
  # s.add_dependency 'devise-guests'
  #
  # s.add_development_dependency 'nokogiri'
  # s.add_development_dependency 'rubocop'
  # s.add_development_dependency 'simplecov'
  # s.add_development_dependency 'simplecov-console'
end
