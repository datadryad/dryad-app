# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'stash/harvester/version'
require 'uri'

Gem::Specification.new do |spec|
  spec.name          = Stash::Harvester::NAME
  spec.version       = Stash::Harvester::VERSION
  spec.authors       = ['David Moles']
  spec.email         = ['david.moles@ucop.edu']
  spec.summary       = 'Harvests metadata from a digital repository'
  spec.description   = 'A gem for harvesting metadata from a digital repository for indexing'
  spec.license       = 'MIT'

  origin_uri = URI(`git config --get remote.origin.url`.chomp)
  spec.homepage = URI::HTTP.build(host: origin_uri.host, path: origin_uri.path.chomp('.git')).to_s

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }

  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = %w(lib db app)

  spec.add_dependency 'activerecord', '~> 4.2', '>= 4.2.3'
  spec.add_dependency 'config-factory', '~> 0.0.1'
  spec.add_dependency 'factory_girl', '~> 4.0'
  spec.add_dependency 'oai', '~> 0.3', '>= 0.3.1'
  spec.add_dependency 'resync-client', '~> 0.3', '>= 0.3.4'
  spec.add_dependency 'sqlite3', '~> 1.3', '>= 1.3.10'
  spec.add_dependency 'standalone_migrations', '~> 4.0', '>= 4.0.2'

  spec.add_dependency 'datacite-mapping', '~> 0.1', '>= 0.1.3'
  spec.add_dependency 'stash-wrapper', '~> 0.0', '>= 0.0.1'

  spec.add_development_dependency 'bundler', '~> 1.7'
  spec.add_development_dependency 'equivalent-xml', '~> 0.6.0'
  spec.add_development_dependency 'rake', '~> 10.4'
  spec.add_development_dependency 'rspec', '~> 3.2'
  spec.add_development_dependency 'simplecov', '~> 0.9.2'
  spec.add_development_dependency 'simplecov-console', '~> 0.2.0'
  spec.add_development_dependency 'rubocop', '~> 0.32', '>= 0.32.1'
  spec.add_development_dependency 'redcarpet', '~> 3.3'
  spec.add_development_dependency 'github-markup', '~> 1.4'
  spec.add_development_dependency 'yard', '~> 0.8'

end
