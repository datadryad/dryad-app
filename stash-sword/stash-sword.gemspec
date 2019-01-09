lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'uri'
require 'stash/sword/module_info'

Gem::Specification.new do |s| # rubocop:disable Metrics/BlockLength
  s.name          = Stash::Sword::NAME
  s.version       = Stash::Sword::VERSION
  s.authors       = ['David Moles']
  s.email         = ['david.moles@ucop.edu']
  s.summary       = 'Stash SWORD 2.0 connector'
  s.description   = 'A minimal SWORD 2.0 connector providing those features needed for Stash'
  s.license       = 'MIT'

  s.required_ruby_version = '~> 2.4'

  origin = `git config --get remote.origin.url`.chomp
  origin_uri = origin.start_with?('http') ? URI(origin) : URI(origin.gsub(%r{git@([^:]+)(.com|.org)[^\/]+}, 'http://\1\2'))
  s.homepage = URI::HTTP.build(host: origin_uri.host, path: origin_uri.path.chomp('.git')).to_s

  s.files         = `git ls-files -z`.split("\x0")
  s.executables   = s.files.grep(%r{^bin/}) { |f| File.basename(f) }

  s.test_files    = s.files.grep(%r{^(test|spec|features)/})
  s.require_paths = ['lib']

  s.add_dependency 'rest-client', '~> 2.0'
  s.add_dependency 'typesafe_enum', '~> 0.1', '>= 0.1.8'
  s.add_dependency 'xml-mapping_extensions', '~> 0.4', '>= 0.4.9'

  s.add_development_dependency 'equivalent-xml', '~> 0.6.0'

  s.add_development_dependency 'bundler', '~> 2.0.0'
  s.add_development_dependency 'diffy', '~> 3.1'
  s.add_development_dependency 'nokogiri', '~> 1.8'
  s.add_development_dependency 'rake', '~> 12.0'
  s.add_development_dependency 'rspec', '~> 3.3'
  s.add_development_dependency 'rubocop', '0.57.2'
  s.add_development_dependency 'simplecov', '~> 0.14'
  s.add_development_dependency 'simplecov-console', '~> 0.4'
  s.add_development_dependency 'webmock', '~> 3.0'
  s.add_development_dependency 'yard', '~> 0.9', '>= 0.9.12'
end
