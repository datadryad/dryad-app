require 'db_spec_helper'

module StashEngine
  describe SwordJob do
    before(:each) do
      expect(StashEngine::Resource.take).to be_nil
    end

    it 'does a thing' do
      expect(true).to be_truthy
    end

  end
end
