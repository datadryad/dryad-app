# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'stash/merritt/module_info'
require 'uri'

Gem::Specification.new do |spec| # rubocop:disable Metrics/BlockLength
  spec.name          = Stash::Merritt::NAME
  spec.version       = Stash::Merritt::VERSION
  spec.authors       = ['David Moles']
  spec.email         = ['david.moles@ucop.edu']
  spec.summary       = 'Merritt integration for Stash'
  spec.description   = 'Packaging and SWORD deposit module for submitting Stash datasets to Merritt'
  spec.license       = 'MIT'

  origin = `git config --get remote.origin.url`.chomp
  origin_uri = origin.start_with?('http') ? URI(origin) : URI(origin.gsub(%r{git@([^:]+)(.com|.org)[^\/]+}, 'http://\1\2'))
  spec.homepage = URI::HTTP.build(host: origin_uri.host, path: origin_uri.path.chomp('.git')).to_s

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }

  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_dependency 'datacite-mapping', '~> 0.2', '>= 0.2.5'
  spec.add_dependency 'rubyzip', '~> 1.1'
  spec.add_dependency 'stash_ezid_datacite', '~> 0.1' # TODO: fold this in
  spec.add_dependency 'merritt-manifest', '~> 0.1', '>= 0.1.1'

  spec.add_dependency 'stash-sword'
  spec.add_dependency 'stash-wrapper'
  spec.add_dependency 'stash_datacite'
  spec.add_dependency 'stash_engine' # TODO: should stash_datacite export this?

  spec.add_development_dependency 'bundler', '~> 1.7'
  spec.add_development_dependency 'rake', '~> 12.0'
  spec.add_development_dependency 'rspec', '~> 3.2'
  spec.add_development_dependency 'simplecov', '~> 0.9.2'
  spec.add_development_dependency 'simplecov-console', '~> 0.2.0'
  spec.add_development_dependency 'rubocop', '~> 0.47'
  spec.add_development_dependency 'yard', '~> 0.8'

  spec.add_development_dependency 'database_cleaner', '~> 1.5'
  spec.add_development_dependency 'diffy', '~> 3.1'
  spec.add_development_dependency 'equivalent-xml', '~> 0.6.0'
  spec.add_development_dependency 'mysql2', '~> 0.3'
  spec.add_development_dependency 'webmock', '~> 1.24'

end
