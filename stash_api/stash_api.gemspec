# frozen_string_literal: true

$LOAD_PATH.push ::File.expand_path('lib', __dir__)

# Maintain your gem's version:
require 'stash_api/version'

# Describe your gem and declare its dependencies:
# rubocop:disable Metrics/BlockLength
Gem::Specification.new do |s|
  s.name        = 'stash_api'
  s.version     = StashApi::VERSION
  s.authors     = ['David Moles']
  s.email       = ['david.moles@ucop.edu']
  s.summary     = 'API access to Stash'
  s.description = 'API access to the Stash data publication and preservation platform'
  s.license     = 'MIT'

  s.required_ruby_version = '~> 2.4.1'

  origin = `git config --get remote.origin.url`.chomp
  origin_uri = origin.start_with?('http') ? URI(origin) : URI(origin.gsub(%r{git@([^:]+)(.com|.org)[^\/]+}, 'http://\1\2'))
  s.homepage = URI::HTTP.build(host: origin_uri.host, path: origin_uri.path.chomp('.git')).to_s

  s.files         = `git ls-files -z`.split("\x0")
  s.executables   = s.files.grep(%r{^bin/}) { |f| ::File.basename(f) }

  s.test_files    = s.files.grep(%r{^(test|spec|features)/})
  s.require_paths = ['lib']

  s.add_dependency 'doorkeeper', '~> 4.4.2'
  s.add_dependency 'mysql2'
  s.add_dependency 'rails', '~> 4.2.8'
  s.add_development_dependency 'byebug'
  s.add_development_dependency 'colorize', '~> 0.8'
  s.add_development_dependency 'combustion'
  s.add_development_dependency 'database_cleaner', '~> 1.5'
  s.add_development_dependency 'diffy', '~> 3.1'
  s.add_development_dependency 'rubocop', '0.57.2'
  s.add_dependency 'stash_datacite'
  s.add_dependency 'stash_engine'
end
# rubocop:enable Metrics/BlockLength
