require 'active_record'
require 'stash/persistence_config'
require_relative 'ar_persistence_manager'

module Stash
  # Configuration for ActiveRecord persistence.
  class ARPersistenceConfig < PersistenceConfig

    can_build_if { |config| config.key?(:adapter) }

    attr_reader :description

    # Creates a new `ARPersistenceConfig`
    # @param persistence_config [Hash] ActiveRecord connection info
    def initialize(**connection_info)
      adapter = connection_info[:adapter]
      @description = describe(connection_info)
      @connection_spec = ActiveRecord::ConnectionAdapters::ConnectionSpecification.new(connection_info, "#{adapter}_connection")
    end

    def create_manager
      connection_pool = ActiveRecord::ConnectionAdapters::ConnectionPool.new(@connection_spec)
      ARPersistenceManager.new(connection_pool)
    end

    def describe(connection_info)
      info_desc = connection_info.map { |k, v| "#{k}: #{v}" }.join(', ')
      "#{self.class} (#{info_desc})"
    end
  end

end
