require 'stash_datacite/engine'
require 'stash_datacite/resource_patch'
module StashDatacite

  def self.config_resource_patch
    Rails.application.config.to_prepare do
      StashDatacite::ResourcePatch.associate_with_resource(StashEngine::Resource)
      # Authorpatch also has to be here, otherwise there were places it wasn't patching before use, resulting in errors
      StashDatacite::AuthorPatch.patch! unless StashEngine::Author.method_defined?(:affiliation)
    end
  end

  class Engine < ::Rails::Engine
    isolate_namespace StashDatacite

    config.autoload_paths << File.expand_path('lib/stash/indexer', __dir__)
    config.autoload_paths << File.expand_path('lib/stash/import', __dir__)

    initializer :append_migrations do |app|
      unless app.root.to_s.match?(root.to_s)
        config.paths['db/migrate'].expanded.each do |expanded_path|
          app.config.paths['db/migrate'] << expanded_path
        end
      end
    end
  end
end
