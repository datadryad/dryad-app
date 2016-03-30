# http://stackoverflow.com/questions/5159607/rails-engine-gems-dependencies-how-to-load-them-into-the-application
# requires all dependencies
Gem.loaded_specs['stash_engine'].dependencies.each do |d|
  begin
    require d.name
  rescue LoadError => e
    logger.warning "Gem is causing load exception: \n #{e}"
  end
end

require 'stash_engine/engine'
module StashEngine
  mattr_accessor :belong_to_resource
  class Engine < ::Rails::Engine
    isolate_namespace StashEngine

    # :nocov:
    initializer :append_migrations do |app|
      unless app.root.to_s.match root.to_s
        config.paths['db/migrate'].expanded.each do |expanded_path|
          app.config.paths['db/migrate'] << expanded_path
        end
      end
    end
    # :nocov:
  end
end
