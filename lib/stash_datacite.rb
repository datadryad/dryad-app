require 'stash_datacite/engine'
require 'stash_datacite/resource_patch'
require 'stash_datacite/test_import'
module StashDatacite
  #mattr_writer :resource_class

  def self.resource_class
    @@resource_class.constantize
  end

  def self.resource_class=(my_class)
    @@resource_class = my_class
    Rails.application.config.to_prepare do
      StashDatacite::ResourcePatch.associate_with_resource(@@resource_class.constantize)
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
