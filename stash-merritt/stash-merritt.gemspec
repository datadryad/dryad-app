lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'stash/merritt/module_info'
require 'uri'

Gem::Specification.new do |s| # rubocop:disable Metrics/BlockLength
  s.name          = Stash::Merritt::NAME
  s.version       = Stash::Merritt::VERSION
  s.authors       = ['David Moles']
  s.email         = ['david.moles@ucop.edu']
  s.summary       = 'Merritt integration for Stash'
  s.description   = 'Packaging and SWORD deposit module for submitting Stash datasets to Merritt'
  s.license       = 'MIT'

  s.required_ruby_version = '~> 2.4'

  origin = `git config --get remote.origin.url`.chomp
  origin_uri = origin.start_with?('http') ? URI(origin) : URI(origin.gsub(%r{git@([^:]+)(.com|.org)[^\/]+}, 'http://\1\2'))
  s.homepage = URI::HTTP.build(host: origin_uri.host, path: origin_uri.path.chomp('.git')).to_s

  s.files         = `git ls-files -z`.split("\x0")
  s.executables   = s.files.grep(%r{^bin/}) { |f| File.basename(f) }

  s.test_files    = s.files.grep(%r{^(test|spec|features)/})
  s.require_paths = ['lib']

  s.add_dependency 'cirneco', '~> 0.9.20' # higher versions cause dependency hell with faraday from Martin's Gems
  s.add_dependency 'datacite-mapping', '~> 0.3'
  s.add_dependency 'ezid-client', '~> 1.5'
  s.add_dependency 'merritt-manifest', '~> 0.1', '>= 0.1.3'
  s.add_dependency 'rest-client', '~> 2.0'
  s.add_dependency 'rubyzip', '~> 1.1'

  s.add_dependency 'stash-sword'
  s.add_dependency 'stash-wrapper'
  s.add_dependency 'stash_datacite'
  s.add_dependency 'stash_engine' # TODO: should stash_datacite export this?

  s.add_development_dependency 'bundler', '~> 2.0.0'
  s.add_development_dependency 'nokogiri', '~> 1.8'
  s.add_development_dependency 'rake', '~> 12.0'
  s.add_development_dependency 'rspec', '~> 3.2'
  s.add_development_dependency 'rubocop', '0.57.2'
  s.add_development_dependency 'simplecov', '~> 0.14'
  s.add_development_dependency 'simplecov-console', '~> 0.4'
  s.add_development_dependency 'yard', '~> 0.9'

  s.add_development_dependency 'database_cleaner', '~> 1.5'
  s.add_development_dependency 'diffy', '~> 3.1'
  s.add_development_dependency 'equivalent-xml', '~> 0.6.0'
  s.add_development_dependency 'mysql2', '~> 0.4'
  s.add_development_dependency 'webmock', '~> 3.0'

end
