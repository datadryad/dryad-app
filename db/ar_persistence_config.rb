require 'active_record'
require 'stash/persistence_config'
require_relative 'ar_persistence_manager'

module Stash
  # Configuration for ActiveRecord persistence.
  class ARPersistenceConfig < PersistenceConfig

    can_build_if { |config| config.key?(:adapter) }

    attr_reader :connection_info

    # Creates a new `ARPersistenceConfig`
    # @param connection_info [Hash] ActiveRecord connection info
    def initialize(**connection_info)
      @connection_info = connection_info
    end

    def create_manager
      ActiveRecord::Base.establish_connection(connection_info)
      ActiveRecord::Migration.verbose = false
      ActiveRecord::Migrator.up 'db/migrate'
      ARPersistenceManager.new
    end

    def description
      info_desc = connection_info.map { |k, v| "#{k}: #{v}" }.join(', ')
      "#{self.class} (#{info_desc})"
    end

  end
end
