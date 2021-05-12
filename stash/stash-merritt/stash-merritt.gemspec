lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

# The following URL clarifies how gemspecs work vs the normal Gemfiles and that gemspecs generally should be more generous with
# version dependencies if released for public use separately.  Some doesn't apply since our gems are usually just a
# way of dividing our application. We may or may not want to check in Gemfile.lock for our private gems since app-specific
# unlike a public gem/engine that is expected to be used in a variety of outside applications.
# https://yehudakatz.com/2010/12/16/clarifying-the-roles-of-the-gemspec-and-gemfile/

# Development dependencies become really somewhat useless or work at cross-purposes in some Ruby/Rails environments
# and you can't really  depend on them to fulfil your dependencies correctly for testing/development environments. See this thread
# where a developer finds them less than useful and very confusing for modern rails environments, yet the maintainers
# don't want to touch the problems, surprises and confusion about development dependencies.
# https://github.com/rubygems/rubygems/issues/1104

# But in any case, the takeaway here is that it's probably better for us to put these requirements into test/development groups
# using the Gemfile for our private gems and engines so the the gem requirements actually get satisfied correctly on
# travis or on new software installs intended for development or testing because add_development_dependency is weak sauce
# for our uses.

require 'stash/merritt/module_info'
require 'uri'

Gem::Specification.new do |s|
  s.name          = Stash::Merritt::NAME
  s.version       = Stash::Merritt::VERSION
  s.authors       = ['David Moles']
  s.email         = ['david.moles@ucop.edu']
  s.summary       = 'Merritt integration for Stash'
  s.description   = 'Packaging and SWORD deposit module for submitting Stash datasets to Merritt'
  s.license       = 'MIT'

  s.required_ruby_version = '~> 2.6.6'

  origin = `git config --get remote.origin.url`.chomp
  origin_uri = origin.start_with?('http') ? URI(origin) : URI(origin.gsub(%r{git@([^:]+)(.com|.org)[^/]+}, 'http://\1\2'))
  s.homepage = URI::HTTP.build(host: origin_uri.host, path: origin_uri.path.chomp('.git')).to_s

  s.files         = `git ls-files -z`.split("\x0")
  s.executables   = s.files.grep(%r{^bin/}) { |f| File.basename(f) }

  s.test_files    = s.files.grep(%r{^(test|spec|features)/})
  s.require_paths = ['lib']

  s.add_dependency 'datacite-mapping', '~> 0.4.0'
  s.add_dependency 'merritt-manifest', '~> 0.1.3'
  s.add_dependency 'rest-client', '~> 2.0'
  s.add_dependency 'rubyzip', '~> 2.3'

  s.add_dependency 'stash_datacite', '~> 0.0'
  s.add_dependency 'stash_engine', '~> 0.0'
  s.add_dependency 'stash-sword', '~> 0.0'
  s.add_dependency 'stash-wrapper', '~> 0.0'

  s.add_development_dependency 'nokogiri', '~> 1.8'
  s.add_development_dependency 'rake', '~> 12.0'
  s.add_development_dependency 'rspec', '~> 3.3'
  s.add_development_dependency 'rubocop', '~> 0.57.2'
  s.add_development_dependency 'simplecov', '~> 0.14'
  s.add_development_dependency 'simplecov-console', '~> 0.4'
  s.add_development_dependency 'yard', '~> 0.9', '>= 0.9.12'

  s.add_development_dependency 'database_cleaner', '~> 1.8', '>= 1.8.5'
  s.add_development_dependency 'diffy', '~> 3.1'
  s.add_development_dependency 'equivalent-xml', '~> 0.6', '>= 0.6.0'
  s.add_development_dependency 'mysql2', '~> 0.4'
  s.add_development_dependency 'webmock', '~> 3.0'

end
