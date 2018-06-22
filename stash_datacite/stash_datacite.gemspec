$LOAD_PATH.push File.expand_path('lib', __dir__)

# Maintain your gem's version:
require 'stash_datacite/version'

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s| # rubocop:disable Metrics/BlockLength
  s.name        = 'stash_datacite'
  s.version     = StashDatacite::VERSION
  s.authors     = ['sfisher']
  s.email       = ['scott.fisher@ucop.edu']
  s.homepage    = 'https://github.com/CDLUC3/stash_datacite'
  s.summary     = 'An engine for working with the DataCite schema in Stash.'
  s.description = 'An engine for working with the DataCite schema in Stash.'
  s.license     = 'MIT'

  s.required_ruby_version = '~> 2.4'

  s.files = Dir['{app,config,db,lib}/**/*', 'MIT-LICENSE', 'Rakefile', 'README.rdoc']
  s.test_files = Dir['test/**/*']

  s.add_dependency 'kaminari'
  s.add_dependency 'leaflet-rails'
  s.add_dependency 'loofah'
  s.add_dependency 'rails', '~> 4.2.4'
  s.add_dependency 'responders', '~> 2.0'
  s.add_dependency 'rubyzip', '>= 1.0.0'

  s.add_dependency 'datacite-mapping', '~> 0.3'
  # TODO: do these need versions?
  s.add_dependency 'stash-wrapper'
  s.add_dependency 'stash_discovery'
  s.add_dependency 'stash_engine'

  s.add_development_dependency 'byebug'
  s.add_development_dependency 'colorize', '~> 0.8'
  s.add_development_dependency 'database_cleaner', '~> 1.5'
  s.add_development_dependency 'diffy', '~> 3.1'
  s.add_development_dependency 'equivalent-xml', '~> 0.6.0'
  s.add_development_dependency 'mysql2', '~> 0.4'
  s.add_development_dependency 'nokogiri', '~> 1.8'
  s.add_development_dependency 'rspec', '~> 3.5'
  s.add_development_dependency 'rspec-rails', '~> 3.5'
  s.add_development_dependency 'rubocop', '0.57.2'
  s.add_development_dependency 'simplecov', '~> 0.14'
  s.add_development_dependency 'simplecov-console', '~> 0.4'
end
