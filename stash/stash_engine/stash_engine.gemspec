$LOAD_PATH.push File.expand_path('lib', __dir__)

require 'stash_engine/version'

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

Gem::Specification.new do |s|
  s.name        = 'stash_engine'
  s.version     = StashEngine::VERSION
  s.authors     = ['sfisher']
  s.email       = ['scott.fisher@ucop.edu']
  s.homepage    = 'https://github.com/CDL-Dryad/stash'
  s.summary     = 'Metadata- and repository-agnostic core Stash functionality'
  s.description = 'Core Stash application functionality independent of repository, metadata schema, or customization'
  s.license     = 'MIT'

  s.required_ruby_version = '~> 2.6.6'

  s.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  s.bindir        = 'exe'
  s.executables   = s.files.grep(%r{^exe/}) { |f| File.basename(f) }
  s.require_paths = ['lib']
  s.test_files = Dir['spec/**/*']

  s.add_dependency 'amoeba'
  # s.add_dependency 'bolognese'
  s.add_dependency 'carrierwave'
  s.add_dependency 'ckeditor', '~> 4.3.0' # lock to 4.x series since upgrading to 5.x blows up until we figure out the upgrade path
  s.add_dependency 'concurrent-ruby'
  s.add_dependency 'daemons'
  s.add_dependency 'database_cleaner'
  s.add_dependency 'datacite-mapping'
  s.add_dependency 'delayed_job_active_record'
  s.add_dependency 'ezid-client'
  s.add_dependency 'filesize'
  s.add_dependency 'font-awesome-rails'
  s.add_dependency 'http'
  s.add_dependency 'httparty'
  s.add_dependency 'httpclient'
  s.add_dependency 'jquery-rails'
  s.add_dependency 'jquery-turbolinks'
  s.add_dependency 'jquery-ui-rails'
  s.add_dependency 'jwt'
  s.add_dependency 'kaminari'
  s.add_dependency 'noid'
  s.add_dependency 'omniauth'
  s.add_dependency 'omniauth-orcid'
  s.add_dependency 'omniauth-rails_csrf_protection'
  s.add_dependency 'omniauth-shibboleth'
  s.add_dependency 'posix-spawn'
  s.add_dependency 'rails', '~> 5.2.6'
  s.add_dependency 'redcarpet'
  s.add_dependency 'rest-client'
  s.add_dependency 'rinku'
  s.add_dependency 'rsolr'
  s.add_dependency 'stripe', '~> 5.38.0'
  s.add_dependency 'zaru'

  # s.add_development_dependency 'colorize'
  # s.add_development_dependency 'database_cleaner'
  # s.add_development_dependency 'diffy'
  # s.add_development_dependency 'equivalent-xml'
  # s.add_development_dependency 'mysql2'
  # s.add_development_dependency 'nokogiri'
  # s.add_development_dependency 'simplecov'
  # s.add_development_dependency 'simplecov-console'
  # s.add_development_dependency 'webmock'
end
