require 'active_record'
require 'stash/persistence_config'
require_relative 'ar_persistence_manager'

module Stash
  # Configuration for ActiveRecord persistence.
  class ARPersistenceConfig < PersistenceConfig

    can_build_if { |config| config.key?(:adapter) }

    attr_reader :description

    # Creates a new `ARPersistenceConfig`
    # @param connection_info [Hash] ActiveRecord connection info
    def initialize(**connection_info)
      @description = describe(connection_info)
      resolver = ActiveRecord::ConnectionAdapters::ConnectionSpecification::Resolver.new({})
      @connection_spec = resolver.spec(connection_info)
    end

    def create_manager
      connection_pool = connection_handler.establish_connection(ActiveRecord::Base, @connection_spec)
      # connection_pool = ActiveRecord::ConnectionAdapters::ConnectionPool.new(@connection_spec)
      ARPersistenceManager.new(connection_pool)
    end

    def connection_handler
      @connection_handler ||= create_connection_handler
    end

    def describe(connection_info)
      info_desc = connection_info.map { |k, v| "#{k}: #{v}" }.join(', ')
      "#{self.class} (#{info_desc})"
    end

    private

    def create_connection_handler
      handler = ActiveRecord::ConnectionAdapters::ConnectionHandler.new
      ActiveRecord::RuntimeRegistry.connection_handler = handler
    end

  end

end
