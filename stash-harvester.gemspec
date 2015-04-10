# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'stash/harvester/version'

Gem::Specification.new do |spec|
  spec.name          = 'stash-harvester'
  spec.version       = Stash::Harvester::VERSION
  spec.authors       = ['David Moles']
  spec.email         = ['david.moles@ucop.edu']
  spec.summary       = 'Harvests OAI-PMH metadata into Solr'
  spec.description   = 'Harvests OAI-PMH metadata from a digital repository into Solr for indexing'
  spec.homepage      = '' # TODO: add homepage
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
#  spec.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_dependency 'rails', '~> 4.2.1'

  spec.add_development_dependency 'bundler', '~> 1.7'
  spec.add_development_dependency 'rake', '~> 10.4'
  spec.add_development_dependency 'rspec', '~> 3.2'
  spec.add_development_dependency 'simplecov', '~> 0.9.2'
  spec.add_development_dependency 'simplecov-console', '~> 0.2.0'
  spec.add_development_dependency 'rubocop', '~> 0.29.1'
  spec.add_development_dependency 'sqlite3'

  spec.add_development_dependency 'rspec-rails'
  spec.add_development_dependency 'factory_girl_rails'

  spec.add_runtime_dependency 'oai', '~> 0.3.1'
  spec.add_runtime_dependency 'rsolr', '~> 1.0.12'

  spec.add_runtime_dependency 'activejob', '~> 4.2.0'
end
