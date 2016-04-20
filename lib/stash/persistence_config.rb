require 'config/factory'
require_relative 'persistence_manager'

module Stash
  class PersistenceConfig
    include ::Config::Factory

    # Constructs a new `PersistenceManager` for this configuration
    # @return [PersistenceManager] a persistence manager for this configuration
    def create_manager
      # TODO: Consider yielding rather than returning, to allow cleanup
      raise NoMethodError, "#{self.class} should override create_manager, but it doesn't"
    end

    def description
      raise NoMethodError, "#{self.class} should override description, but it doesn't"
    end
  end
end
