require 'blacklight'
require 'geoblacklight'
# these devise lines must be required otherwise geoblacklight barfs, but only on stage.
require 'devise'
require 'devise/orm/active_record'
require 'rsolr'

# For undocumented reasons, sass-rails won't load without an explicit require
require 'sass-rails'

module StashDiscovery
  class Engine < ::Rails::Engine
    # :nocov:
    initializer :append_migrations do |app|
      unless app.root.to_s.match?(root.to_s)
        config.paths['db/migrate'].expanded.each do |expanded_path|
          app.config.paths['db/migrate'] << expanded_path
        end
      end
    end

    # this requires some open class overrides (ie, Monkeypatches to geoblacklight)
    config.to_prepare do
      Dir.glob(Engine.root + 'app/decorators/**/*_decorator.rb').each do |c|
        require_dependency(c)
      end
    end
    # :nocov:

  end
end
