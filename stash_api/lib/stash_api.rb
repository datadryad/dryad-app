# frozen_string_literal: true

require 'stash_api/engine'
require 'doorkeeper'
require 'byebug'

module StashApi
  class Engine < ::Rails::Engine
    isolate_namespace StashApi

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
