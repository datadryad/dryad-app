require 'spec_helper'

module StashApi
  RSpec.describe DatasetParser do
    before(:each) do
      app = double(Rails::Application)
      allow(app).to receive(:stash_mount).and_return('/api')
      # TODO: We need to figure out how to load the other engines without errors (spec_helper probably)
      # allow(StashEngine).to receive(:app).and_return(app)
    end

    after(:each) do
    end

    describe :initialize do
      it 'creates a dataset parser--this is a fake test for now' do
        # TODO: make real test
        expect(true).to eq(true)
      end
    end
  end
end
