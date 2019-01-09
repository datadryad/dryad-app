lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'uri'
require 'stash/wrapper/module_info'

Gem::Specification.new do |s| # rubocop:disable Metrics/BlockLength
  s.name          = Stash::Wrapper::NAME
  s.version       = Stash::Wrapper::VERSION
  s.authors       = ['David Moles']
  s.email         = ['david.moles@ucop.edu']
  s.summary       = 'Parses and generates Stash wrapper XML documents'
  s.description   = 'A gem for working with the Stash wrapper XML format'
  s.license       = 'MIT'

  s.required_ruby_version = '~> 2.4'

  origin = `git config --get remote.origin.url`.chomp
  origin_uri = origin.start_with?('http') ? URI(origin) : URI(origin.gsub(%r{git@([^:]+)(.com|.org)[^\/]+}, 'http://\1\2'))
  s.homepage = URI::HTTP.build(host: origin_uri.host, path: origin_uri.path.chomp('.git')).to_s

  s.files         = `git ls-files -z`.split("\x0")
  s.executables   = s.files.grep(%r{^bin/}) { |f| File.basename(f) }

  s.test_files    = s.files.grep(%r{^(test|spec|features)/})
  s.require_paths = ['lib']

  # TODO: remove once we're on Rails 5, probably
  s.add_dependency 'thor', '0.19.1' # see https://github.com/erikhuda/thor/issues/538

  s.add_dependency 'typesafe_enum', '~> 0.1', '>= 0.1.8'
  s.add_dependency 'xml-mapping_extensions', '~> 0.4', '>= 0.4.9'

  s.add_development_dependency 'bundler', '~> 2.0.0'
  s.add_development_dependency 'diffy', '~> 3.1'
  s.add_development_dependency 'equivalent-xml', '~> 0.6.0'
  s.add_development_dependency 'nokogiri', '~> 1.8'
  s.add_development_dependency 'rake', '~> 12.0'
  s.add_development_dependency 'rspec', '~> 3.2'
  s.add_development_dependency 'rubocop', '0.57.2'
  s.add_development_dependency 'simplecov', '~> 0.14'
  s.add_development_dependency 'simplecov-console', '~> 0.4'
  s.add_development_dependency 'yard', '~> 0.9', '~> 0.9.12'

end
