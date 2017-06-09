require 'stash_datacite/engine'
require 'stash_datacite/resource_patch'
module StashDatacite

  def self.config_resource_patch
    Rails.application.config.to_prepare do
      StashDatacite::ResourcePatch.associate_with_resource(StashEngine::Resource)
    end
  end

  class Engine < ::Rails::Engine
    isolate_namespace StashDatacite

    initializer :append_migrations do |app|
      unless app.root.to_s.match root.to_s
        config.paths['db/migrate'].expanded.each do |expanded_path|
          app.config.paths['db/migrate'] << expanded_path
        end
      end
    end
  end
end
