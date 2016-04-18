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

    describe '#description' do
      it 'includes the class name and connection info' do
        env = ::Config::Factory::Environment.load_file('spec/data/stash-harvester.yml')
        config = PersistenceConfig.for_environment(env, :db)
        desc = config.description
        expect(desc).to include(ARPersistenceConfig.to_s)
        expect(desc).to include('adapter: sqlite3')
        expect(desc).to include('database: :memory:')
        expect(desc).to include('pool: 5')
        expect(desc).to include('timeout: 5000')
      end
    end
  end
end
