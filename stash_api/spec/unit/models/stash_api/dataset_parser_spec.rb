require 'spec_helper'

module StashApi
  RSpec.describe DatasetParser do
    before(:each) do
      app = double(Rails::Application)
      allow(app).to receive(:stash_mount).and_return('/api')
      allow(StashEngine).to receive(:app).and_return(app)
    end

    after(:each) do
    end

    describe :initialize do
      it 'creates a dataset parser' do
        # TODO: make real test
        expect(true).to eq(true)
      end
    end
  end
end
