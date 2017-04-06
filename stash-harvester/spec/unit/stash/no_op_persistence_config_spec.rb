require 'spec_helper'

module Stash
  describe NoOpPersistenceConfig do

    attr_reader :config

    before(:each) do
      @config = NoOpPersistenceConfig.new
    end

    describe '#description' do
      it 'describes' do
        expect(config.description).to include('NoOpPersistenceConfig')
      end
    end

    describe '#create_manager' do
      it 'creates a manager' do
        expect(config.create_manager).to be_a(NoOpPersistenceManager)
      end
    end
  end
end
