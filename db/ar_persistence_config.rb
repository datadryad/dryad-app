require 'active_record'
require 'stash/persistence_config'
require_relative 'ar_persistence_manager'

module Stash
  # Configuration for ActiveRecord persistence.
  class ARPersistenceConfig < PersistenceConfig
    # Creates a new `ARPersistenceConfig`
    # @param connection_info [Hash] ActiveRecord connection info
    def initialize(**connection_info)
      @connection_spec = ActiveRecord::ConnectionAdapters::ConnectionSpecification.new(connection_info)
    end

    def create_manager
      connection_pool = ActiveRecord::ConnectionAdapters::ConnectionPool.new(@connection_spec)
      ARPersistenceManager.new(connection_pool)
    end
  end

end
