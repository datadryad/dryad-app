# coding: utf-8

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'uri'
require 'stash/sword/module_info'

Gem::Specification.new do |spec| # rubocop:disable Metrics/BlockLength
  spec.name          = Stash::Sword::NAME
  spec.version       = Stash::Sword::VERSION
  spec.authors       = ['David Moles']
  spec.email         = ['david.moles@ucop.edu']
  spec.summary       = 'Stash SWORD 2.0 connector'
  spec.description   = 'A minimal SWORD 2.0 connector providing those features needed for Stash'
  spec.license       = 'MIT'

  origin = `git config --get remote.origin.url`.chomp
  origin_uri = origin.start_with?('http') ? URI(origin) : URI(origin.gsub(%r{git@([^:]+)(.com|.org)[^\/]+}, 'http://\1\2'))
  spec.homepage = URI::HTTP.build(host: origin_uri.host, path: origin_uri.path.chomp('.git')).to_s

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }

  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_dependency 'rest-client', '~> 2.0'
  spec.add_dependency 'typesafe_enum', '~> 0.1', '>= 0.1.7'
  spec.add_dependency 'xml-mapping_extensions', '~> 0.4', '>= 0.4.1'

  spec.add_development_dependency 'equivalent-xml', '~> 0.6.0'

  spec.add_development_dependency 'bundler', '~> 1.7'
  spec.add_development_dependency 'rake', '~> 12.0'
  spec.add_development_dependency 'rspec', '~> 3.3'
  spec.add_development_dependency 'simplecov', '~> 0.9.2'
  spec.add_development_dependency 'simplecov-console', '~> 0.2.0'
  spec.add_development_dependency 'rubocop', '~> 0.49'
  spec.add_development_dependency 'webmock', '~> 3.0'
  spec.add_development_dependency 'yard', '~> 0.8'
end
