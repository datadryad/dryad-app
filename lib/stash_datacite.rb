# http://stackoverflow.com/questions/5159607/rails-engine-gems-dependencies-how-to-load-them-into-the-application
# requires all dependencies

#Gem.loaded_specs['stash_datacite'].dependencies.each do |d|
#  require d.name
#end

require 'stash_datacite/engine'
require 'stash_datacite/resource_patch'

module StashDatacite
  #mattr_writer :resource_class

  def self.resource_class
    @@resource_class.constantize
  end

  def self.resource_class=(my_class)
    @@resource_class = my_class
    StashDatacite::ResourcePatch.associate_with_resource(@@resource_class.constantize)
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
