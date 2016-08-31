$:.push File.expand_path('../lib', __FILE__)

# Maintain your gem's version:
require 'stash_discovery/version'

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = 'stash_discovery'
  s.version     = StashDiscovery::VERSION
  s.authors     = ['David Moles']
  s.email       = ['david.moles@ucop.edu']
  s.homepage    = 'https://github.com/CDLUC3/stash_discovery'
  s.summary     = 'The discovery module for Stash'
  s.description = 'GeoBlacklight-based discovery module for Stash'
  s.license     = 'MIT'

  s.files = Dir['{app,config,db,lib}/**/*', 'MIT-LICENSE', 'Rakefile', 'README.rdoc']
  s.test_files = Dir['test/**/*']

  s.add_dependency 'rails', '~> 4.2'
  s.add_dependency 'geoblacklight', '~> 1.1.2'
  s.add_dependency 'config'
  s.add_dependency 'rsolr'
  #s.add_dependency 'jquery-rails', '~> 4.1'
  #s.add_dependency 'sass-rails', '~> 5.0'
  #s.add_dependency 'turbolinks', '~> 2.5'

  # extra deps from generated GeoBlacklight app
  s.add_dependency 'devise-guests', '~> 0.5'

  s.add_development_dependency 'sqlite3'
end

