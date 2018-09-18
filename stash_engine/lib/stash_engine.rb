require 'rails'
require 'redcarpet'
require 'omniauth'
require 'redcarpet'
require 'omniauth'
require 'omniauth-shibboleth'
# require 'omniauth-google-oauth2'
require 'omniauth-orcid'
require 'jquery-rails'
require 'jquery-ui-rails'
require 'jquery-turbolinks'
require 'carrierwave'
require 'jquery-fileupload-rails'
require 'filesize'
require 'kaminari'
require 'amoeba'
require 'font-awesome-rails' # perhaps not needed because of way Joel did his integration
require 'zeroclipboard-rails'

require 'stash_engine/engine'
require 'stash/repo'
require 'stash/event_data'
require 'stash/datacite_metadata'

module StashEngine
  class Engine < ::Rails::Engine
    isolate_namespace StashEngine

    # :nocov:
    initializer :append_migrations do |app|
      unless app.root.to_s.match?(root.to_s)
        config.paths['db/migrate'].expanded.each do |expanded_path|
          app.config.paths['db/migrate'] << expanded_path
        end
      end
    end
    # :nocov:
  end
end
