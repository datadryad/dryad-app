require 'config/factory'
require 'ar_persistence_config'

module Stash
  describe ARPersistenceConfig do
    it 'loads from a config file' do
      env = ::Config::Factory::Environments.load_file('spec/data/stash-harvester.yml')[:test]
      config = PersistenceConfig.for_environment(env, :db)
      expect(config).to be_an(ARPersistenceConfig)
    end

    describe 'create_manager' do
      it 'creates a manager' do
        begin
          env = ::Config::Factory::Environments.load_file('spec/data/stash-harvester.yml')[:test]
          connection_info = env.args_for(:db).map { |k, v| [k.to_sym, v] }.to_h
          config = PersistenceConfig.for_environment(env, :db)

          expect(ActiveRecord::Base).to receive(:establish_connection).with(connection_info)
          expect(config.create_manager).to be_an(ARPersistenceManager)
        ensure
          allow(ActiveRecord::Base).to receive(:establish_connection).and_call_original
        end
      end
    end

    describe '#description' do
      it 'includes the class name and connection info' do
        env = ::Config::Factory::Environments.load_file('spec/data/stash-harvester.yml')[:test]
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
