require 'db_spec_helper'
require_relative '../../../../../spec_helpers/factory_helper'
require 'byebug'
# require 'test_helper'

# something wacky about our setup requires this here.  It seems to be either a) never requiring them or b) requiring them 1000 times otherwise
# FactoryBot.find_definitions

module StashApi
  RSpec.describe Dataset do
    before(:each) do

      # all these doubles are required because I can't get a url helper for creating URLs inside the tests.
      generic_path = double('generic_path')
      allow(generic_path).to receive(:dataset_path).and_return('dataset_foobar_path')
      allow(generic_path).to receive(:dataset_versions_path).and_return('dataset_versions_foobar_path')
      allow(generic_path).to receive(:version_path).and_return('version_foobar_path')

      allow(Dataset).to receive(:api_url_helper).and_return(generic_path)

      # These are the factories for test data and create a basic identifier and resource
      resource_state = create(:resource_state)

      @user = create(:user)
      @identifier = create(:identifier) do |identifier|
        identifier.resources.create do |r|
          r.user = @user
          r.current_resource_state_id = resource_state
          r.current_editor_id = @user.id
          r.title = 'My Cats Have Fleas'
          r.tenant_id = @user.tenant_id
        end
      end
      create(:version) do |v|
        v.resource = @identifier.resources.first
      end

    end

    # this is just a basic test to be sure FactoryBot works.  It likes to break a lot.
    describe :factories do
      it 'creates a FactoryBot factory that works' do
        expect(@identifier).to be_valid
      end
    end

    describe :basic_dataset_view do

      before(:each) do
        @dataset = Dataset.new(identifier: @identifier.to_s)
        @metadata = @dataset.metadata
      end

      it 'shows an appropriate string identifier under id' do
        expect(@metadata[:identifier]).to eq('doi:138/238/2238')
      end

      it 'shows correct title' do
        expect(@metadata[:title]).to eq('My Cats Have Fleas')
      end

      it 'shows a version number' do
        expect(@metadata[:versionNumber]).to eq(1)
      end

      it 'shows a correct version status' do
        expect(@metadata[:versionStatus]).to eq('in_progress')
      end

      it 'shows skipDataciteUpdate' do
        expect(@metadata[:skipDataciteUpdate]).to eq(false)
      end

      it 'shows Unsubmitted curationStatus' do
        expect(@metadata[:curationStatus]).to eq('Unsubmitted')
      end

      it 'shows Submitted curationStatus' do
        @c_a = create(:curation_activity)
        @c_a.update(identifier_id: @identifier.id)
        @dataset = Dataset.new(identifier: @identifier.to_s)
        @metadata = @dataset.metadata
        expect(@metadata[:curationStatus]).to eq('Submitted')
      end

    end

  end
end
