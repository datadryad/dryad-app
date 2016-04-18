require 'spec_helper'

module Stash
  describe PersistenceConfig do
    describe '#create_manager' do
      it 'is abstract' do
        config = PersistenceConfig.new
        expect { config.create_manager }.to raise_error(NoMethodError)
      end
    end

    describe '#description' do
      it 'is abstract' do
        config = PersistenceConfig.new
        expect { config.description }.to raise_error(NoMethodError)
      end
    end
  end
end
