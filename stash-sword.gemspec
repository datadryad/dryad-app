# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'uri'
require 'stash/sword2/module_info'

Gem::Specification.new do |spec|
  spec.name          = Stash::Sword2::NAME
  spec.version       = Stash::Sword2::VERSION
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

  spec.add_dependency 'xml-mapping_extensions', '~> 0.3', '>= 0.3.7'

  # spec.add_dependency 'rest-client', '~> 1.8'
  # spec.add_dependency 'sword2ruby', '~> 1.0'
  # spec.add_dependency 'multipart-post', '~> 2.0'
  #
  # spec.add_dependency 'stash-wrapper', '~> 0.1', '>= 0.1.2'
  # spec.add_dependency 'datacite-mapping', '~> 0.1', '>= 0.1.8'

  spec.add_development_dependency 'bundler', '~> 1.7'
  spec.add_development_dependency 'rake', '~> 10.4'
  spec.add_development_dependency 'rspec', '~> 3.3'
  spec.add_development_dependency 'simplecov', '~> 0.9.2'
  spec.add_development_dependency 'simplecov-console', '~> 0.2.0'
  spec.add_development_dependency 'rubocop', '~> 0.32.1'
  spec.add_development_dependency 'webmock', '~> 1.24'
  spec.add_development_dependency 'yard', '~> 0.8'
end
