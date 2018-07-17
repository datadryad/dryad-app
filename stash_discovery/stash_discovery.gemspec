$LOAD_PATH.push File.expand_path('../lib', __FILE__)

# Maintain your gem's version:
require 'stash_discovery/version'

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s| # rubocop:disable Metrics/BlockLength
  s.name        = 'stash_discovery'
  s.version     = StashDiscovery::VERSION
  s.authors     = ['David Moles']
  s.email       = ['david.moles@ucop.edu']
  s.homepage    = 'https://github.com/CDL-Dryad/stash'
  s.summary     = 'The discovery module for Stash'
  s.description = 'GeoBlacklight-based discovery module for Stash'
  s.license     = 'MIT'

  s.required_ruby_version = '~> 2.2'

  s.files = Dir['{app,config,db,lib}/**/*', 'MIT-LICENSE', 'Rakefile', 'README.rdoc']
  s.test_files = Dir['test/**/*']

  # TODO: remove once we're on Rails 5, probably
  s.add_dependency 'thor', '0.19.1' # hack to get around https://github.com/erikhuda/thor/issues/538

  s.add_dependency 'blacklight', '~> 6.5.0'
  s.add_dependency 'config'
  s.add_dependency 'ffi', '1.9.21' # peg to 1.9.21 for https://github.com/ffi/ffi/issues/640
  s.add_dependency 'geoblacklight', '~> 1.1.2'
  s.add_dependency 'jquery-rails', '~> 4.1'
  s.add_dependency 'rails', '~> 4.2'
  s.add_dependency 'rsolr'
  s.add_dependency 'sass-rails', '~> 5.0'
  s.add_dependency 'solr_wrapper'
  s.add_dependency 'turbolinks'

  # extra deps from generated GeoBlacklight app
  s.add_dependency 'devise-guests', '~> 0.5'

  s.add_development_dependency 'nokogiri', '~> 1.8'
  s.add_development_dependency 'rspec', '~> 3.2'
  s.add_development_dependency 'rubocop', '0.52.1'
  s.add_development_dependency 'simplecov', '~> 0.14'
  s.add_development_dependency 'simplecov-console', '~> 0.4'
  s.add_development_dependency 'sqlite3'
end
