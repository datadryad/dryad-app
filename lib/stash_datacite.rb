require "stash_datacite/engine"

module StashDatacite
  mattr_accessor :resource_class
  def self.resource_class
    @@resource_class.constantize
  end
  class Engine < ::Rails::Engine
    isolate_namespace StashDatacite

      initializer :append_migrations do |app|
      unless app.root.to_s.match root.to_s
        config.paths["db/migrate"].expanded.each do |expanded_path|
          app.config.paths["db/migrate"] << expanded_path
        end
      end
    end

  end
end