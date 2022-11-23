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

require 'uri'
require 'stash/sword/module_info'

Gem::Specification.new do |s|
  s.name          = Stash::Sword::NAME
  s.version       = Stash::Sword::VERSION
  s.authors       = ['David Moles']
  s.email         = ['david.moles@ucop.edu']
  s.summary       = 'Stash SWORD 2.0 connector'
  s.description   = 'A minimal SWORD 2.0 connector providing those features needed for Stash'
  s.license       = 'MIT'

  s.required_ruby_version = '~> 3.0.4'

  origin = `git config --get remote.origin.url`.chomp
  origin_uri = origin.start_with?('http') ? URI(origin) : URI(origin.gsub(%r{git@([^:]+)(.com|.org)[^/]+}, 'http://\1\2'))
  s.homepage = URI::HTTP.build(host: origin_uri.host, path: origin_uri.path.chomp('.git')).to_s

  s.files         = `git ls-files -z`.split("\x0")
  s.executables   = s.files.grep(%r{^bin/}) { |f| File.basename(f) }

  s.require_paths = ['lib']

  s.add_dependency 'rest-client', '~> 2.1.0'
  s.add_dependency 'typesafe_enum', '~> 0.1.9'
  s.add_dependency 'xml-mapping_extensions', '~> 0.4.9'

  s.add_development_dependency 'equivalent-xml', '~> 0.6.0'

  # s.add_development_dependency 'diffy'
  # s.add_development_dependency 'nokogiri'
  # s.add_development_dependency 'rake'
  # s.add_development_dependency 'rubocop'
  # s.add_development_dependency 'simplecov'
  # s.add_development_dependency 'simplecov-console'
  # s.add_development_dependency 'webmock'
  # s.add_development_dependency 'yard'
  s.metadata['rubygems_mfa_required'] = 'true'
end
