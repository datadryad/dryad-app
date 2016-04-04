require 'db_spec_helper'
require 'config/factory'
require 'ar_persistence_config'

module Stash
  describe ARPersistenceConfig do
    it 'loads from a config file' do
      env = ::Config::Factory::Environment.load_file('spec/data/stash-harvester.yml')
      config = PersistenceConfig.for_environment(env, :db)
      expect(config).to be_an(ARPersistenceConfig)
    end
  end
end
