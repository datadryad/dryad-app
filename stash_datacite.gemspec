$:.push File.expand_path('../lib', __FILE__)

# Maintain your gem's version:
require 'stash_datacite/version'

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = 'stash_datacite'
  s.version     = StashDatacite::VERSION
  s.authors     = ['sfisher']
  s.email       = ['scott.fisher@ucop.edu']
  s.homepage    = 'https://github.com/CDLUC3/stash_datacite'
  s.summary     = 'An engine for working with the DataCite schema in Stash.'
  s.description = 'An engine for working with the DataCite schema in Stash.'
  s.license     = 'MIT'

  s.files = Dir['{app,config,db,lib}/**/*', 'MIT-LICENSE', 'Rakefile', 'README.rdoc']
  s.test_files = Dir['test/**/*']

  s.add_dependency 'rails', '~> 4.2.4'
  s.add_development_dependency 'mysql2'
  s.add_dependency 'responders', '~> 2.0'
  s.add_dependency 'leaflet-rails'
  s.add_dependency 'datacite-mapping', '~> 0.2', '>= 0.2.2'
  s.add_dependency 'kaminari'
  s.add_dependency 'stash-wrapper', '~> 0.1', '>= 0.1.11.1'
  s.add_dependency 'rubyzip'
end
