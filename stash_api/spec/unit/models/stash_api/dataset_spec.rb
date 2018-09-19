require 'db_spec_helper'
require 'factory_helper'
require 'byebug'
# require 'test_helper'

# something wacky about our setup requires this here.  It seems to be either a) never requiring them or b) requiring them 1000 times otherwise
FactoryBot.find_definitions

module StashApi
  RSpec.describe Dataset do
    before(:each) do
      @identifier = create(:identifier)
    end

    # this is just a basic test to be sure FactoryBot works.  It likes to break a lot.
    describe :factories do
      it 'creates a FactoryBot factory that works' do
        expect(@identifier).to be_valid
      end
    end

    describe :dataset_view do

    end

  end
end
