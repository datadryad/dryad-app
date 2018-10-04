# require 'db_spec_helper'
require_relative '../../../../spec_helpers/factory_helper'
require 'byebug'
# require 'test_helper'

# something wacky about our setup requires this here.  It seems to be either a) never requiring them or b) requiring them 1000 times otherwise
# FactoryBot.find_definitions

module StashEngine
  RSpec.describe CurationActivity do
    # this is just a basic test to be sure FactoryBot works.  It likes to break a lot.
    describe :factories do
      it 'creates a FactoryBot factory that works' do
        @identifier = create(:identifier)
        expect(@identifier).to be_valid
      end
    end

    describe :basic_curation_activity do

      before(:each) do
        @user = create(:user)
        @identifier = create(:identifier)
        @curation_activity = create(:curation_activity)
        @curation_activity.update(identifier_id: @identifier.id)
        # @curation_activity.update(user: @user.id)
      end

      it 'shows the appropriate dataset identifier' do
        expect(@curation_activity.stash_identifier.to_s).to eq(@identifier.to_s)
      end
    end

  end
end
