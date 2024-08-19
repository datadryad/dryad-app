require 'blacklight'
require 'rsolr'

# For undocumented reasons, sass-rails won't load without an explicit require
require 'bootstrap'
# require 'bootstrap-sass'

module StashDiscovery
  class Engine < ::Rails::Engine
    # assets are not loading from subdirectories of blacklight so trying to add them to asset path
    # config.assets.paths << Blacklight::Engine.root.join('app', 'assets', 'stylesheets', 'blacklight')
    # :nocov:
    initializer :append_migrations do |app|
      unless app.root.to_s.match?(root.to_s)
        config.paths['db/migrate'].expanded.each do |expanded_path|
          app.config.paths['db/migrate'] << expanded_path
        end
      end
    end

    # this requires some open class overrides (ie, Monkeypatches to Blacklight)
    config.to_prepare do
      Dir.glob("#{Rails.root}/app/overrides/**/*_override.rb").each do |override|
        load override
      end
    end
    # :nocov:
  end
end
