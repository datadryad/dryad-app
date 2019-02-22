$LOAD_PATH.push File.expand_path('lib', __dir__)

require 'stash_engine/version'

Gem::Specification.new do |s| # rubocop:disable Metrics/BlockLength
  s.name        = 'stash_engine'
  s.version     = StashEngine::VERSION
  s.authors     = ['sfisher']
  s.email       = ['scott.fisher@ucop.edu']
  s.homepage    = 'https://github.com/CDL-Dryad/stash'
  s.summary     = 'Metadata- and repository-agnostic core Stash functionality'
  s.description = 'Core Stash application functionality independent of repository, metadata schema, or customization'
  s.license     = 'MIT'

  s.required_ruby_version = '~> 2.4'

  s.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  s.bindir        = 'exe'
  s.executables   = s.files.grep(%r{^exe/}) { |f| File.basename(f) }
  s.require_paths = ['lib']
  s.test_files = Dir['spec/**/*']

  # TODO: remove once we're on Rails 5, probably
  s.add_dependency 'thor', '0.19.1' # HACK: to get around https://github.com/erikhuda/thor/issues/538

  s.add_dependency 'amoeba', '~> 3.0.0'
  s.add_dependency 'carrierwave', '~> 0.10.0'
  s.add_dependency 'cirneco', '~> 0.9.20' # higher versions cause dependency hell with faraday from Martin's Gems
  s.add_dependency 'ckeditor'
  s.add_dependency 'concurrent-ruby', '~> 1.0'
  s.add_dependency 'datacite-mapping', '~> 0.3'
  s.add_dependency 'ezid-client', '~> 1.5'
  s.add_dependency 'filesize', '~> 0.1.1'
  s.add_dependency 'font-awesome-rails'
  s.add_dependency 'httpclient', '~> 2.8.3'
  s.add_dependency 'jquery-fileupload-rails', '~> 0.4.6'
  s.add_dependency 'jquery-rails'
  s.add_dependency 'jquery-turbolinks', '~> 2.1.0'
  s.add_dependency 'jquery-ui-rails'
  s.add_dependency 'kaminari'
  s.add_dependency 'noid', '~> 0.9.0'
  s.add_dependency 'omniauth', '~> 1.8.1'
  # s.add_dependency 'omniauth-google-oauth2', '~> 0.5.3' no longer used and causes problems with faraday and cirneco
  s.add_dependency 'omniauth-orcid', '~> 2.1.1'
  s.add_dependency 'omniauth-shibboleth', '~> 1.2.1'
  s.add_dependency 'rails', '~> 4.2.11'
  s.add_dependency 'redcarpet', '~> 3.3'
  s.add_dependency 'rest-client'
  s.add_dependency 'rinku'
  s.add_dependency 'rsolr', '~> 1.1.2'
  s.add_dependency 'sortable-table'
  s.add_dependency 'wicked_pdf', '~> 1.1.0'
  s.add_dependency 'wkhtmltopdf-binary', '~> 0.12.3.1'

  s.add_development_dependency 'byebug'
  s.add_development_dependency 'chromedriver-helper'
  s.add_development_dependency 'colorize', '~> 0.8'
  s.add_development_dependency 'database_cleaner', '~> 1.5'
  s.add_development_dependency 'diffy', '~> 3.1'
  s.add_development_dependency 'equivalent-xml', '~> 0.6.0'
  s.add_development_dependency 'mysql2', '~> 0.4'
  s.add_development_dependency 'nokogiri', '~> 1.8'
  s.add_development_dependency 'rspec', '~> 3.5'
  s.add_development_dependency 'rspec-rails', '~> 3.5'
  s.add_development_dependency 'rubocop', '0.57.2'
  s.add_development_dependency 'scss_lint'
  s.add_development_dependency 'simplecov', '~> 0.14'
  s.add_development_dependency 'simplecov-console', '~> 0.4'
  s.add_development_dependency 'webmock', '~> 3.0'
end
