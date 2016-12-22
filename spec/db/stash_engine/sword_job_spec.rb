require 'rails_helper'

module StashEngine
  describe SubmitJob do
    before(:each) do
      expect(StashEngine::Resource.find).to be_nil
    end
  end
end
