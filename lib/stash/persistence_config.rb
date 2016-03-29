require 'config/factory'

module Stash
  class PersistenceConfig
    include ::Config::Factory

    key :db

    # Constructs a new `PersistenceManager` for this configuration
    # @return [PersistenceManager] a persistence manager for this configuration
    def create_manager
      raise NoMethodError, "#{self.class} should override create_manager, but it doesn't"
    end
  end
end
