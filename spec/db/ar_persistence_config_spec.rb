require 'db_spec_helper'
require 'config/factory'
require 'ar_persistence_config'

module Stash
  class MockPool
    def with_connection
      yield if block_given?
    end
  end

  describe ARPersistenceConfig do
    it 'loads from a config file' do
      env = ::Config::Factory::Environment.load_file('spec/data/stash-harvester.yml')
      config = PersistenceConfig.for_environment(env, :db)
      expect(config).to be_an(ARPersistenceConfig)
    end

    it 'creates a connection pool' do
      begin
        env = ::Config::Factory::Environment.load_file('spec/data/stash-harvester.yml')
        config = PersistenceConfig.for_environment(env, :db)

        pool = MockPool.new
        expect(ActiveRecord::ConnectionAdapters::ConnectionPool).to receive(:new) { pool }
        expect(ARPersistenceManager).to receive(:new).with(pool).and_call_original
        mgr = config.create_manager
        expect(mgr).to be_an(ARPersistenceManager)
      ensure
        allow(ActiveRecord::ConnectionAdapters::ConnectionPool).to receive(:new).and_call_original
        allow(ARPersistenceManager).to receive(:new).with(pool).and_call_original
      end
    end
  end
end
