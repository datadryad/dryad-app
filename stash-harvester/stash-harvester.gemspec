lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'stash/harvester/version'
require 'uri'

Gem::Specification.new do |s| # rubocop:disable Metrics/BlockLength
  s.name          = Stash::Harvester::NAME
  s.version       = Stash::Harvester::VERSION
  s.authors       = ['David Moles']
  s.email         = ['david.moles@ucop.edu']
  s.summary       = 'Harvests metadata from a digital repository'
  s.description   = 'A gem for harvesting metadata from a digital repository for indexing'
  s.license       = 'MIT'

  s.required_ruby_version = '~> 2.4'

  origin = `git config --get remote.origin.url`.chomp
  origin_uri = origin.start_with?('http') ? URI(origin) : URI(origin.gsub(%r{git@([^:]+)(.com|.org)[^\/]+}, 'http://\1\2'))
  s.homepage = URI::HTTP.build(host: origin_uri.host, path: origin_uri.path.chomp('.git')).to_s

  s.files         = `git ls-files -z`.split("\x0")
  s.executables   = s.files.grep(%r{^bin/}) { |f| File.basename(f) }

  s.test_files    = s.files.grep(%r{^(test|spec|features)/})
  s.require_paths = %w[lib db app]

  s.add_dependency 'activerecord', '~> 4.2', '>= 4.2.3'
  s.add_dependency 'config-factory', '~> 0.0', '>= 0.0.8'
  s.add_dependency 'factory_girl', '~> 4.0'
  s.add_dependency 'oai', '~> 0.3', '>= 0.3.1'
  s.add_dependency 'rest-client', '~> 2.0'
  s.add_dependency 'resync-client', '~> 0.4', '>= 0.4.6'
  s.add_dependency 'rsolr', '~> 1.1'
  s.add_dependency 'sqlite3', '~> 1.3', '>= 1.3.10'
  s.add_dependency 'standalone_migrations', '~> 5.0'

  s.add_dependency 'datacite-mapping', '~> 0.3'
  s.add_dependency 'stash-wrapper'

  s.add_development_dependency 'bundler', '~> 2.0.0'
  s.add_development_dependency 'diffy', '~> 3.1'
  s.add_development_dependency 'equivalent-xml', '~> 0.6.0'
  s.add_development_dependency 'github-markup', '~> 1.4'
  s.add_development_dependency 'nokogiri', '~> 1.8'
  s.add_development_dependency 'rake', '~> 12.0'
  s.add_development_dependency 'redcarpet', '~> 3.3'
  s.add_development_dependency 'rspec', '~> 3.2'
  s.add_development_dependency 'rubocop', '0.57.2'
  s.add_development_dependency 'simplecov', '~> 0.14'
  s.add_development_dependency 'simplecov-console', '~> 0.4'
  s.add_development_dependency 'webmock', '~> 3.0'
  s.add_development_dependency 'yard', '~> 0.9', '>= 0.9.12'

end
