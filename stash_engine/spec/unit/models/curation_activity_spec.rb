# require 'db_spec_helper'
require 'ostruct'
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
        @mock_idgen = double('idgen')
        allow(@mock_idgen).to receive('update_identifier_metadata!'.intern).and_raise('submitted DOI')
        allow(Stash::Doi::IdGen).to receive(:make_instance).and_return(@mock_idgen)
      end

      it 'shows the appropriate dataset identifier' do
        expect(@curation_activity.stash_identifier.to_s).to eq(@identifier.to_s)
      end
    end

    describe :submit_to_datacite do
      before(:each) do
        @user = create(:user)
        @identifier = create(:identifier)
        @resource = create(:resource, identifier_id: @identifier.id)
        @resource_state = create(:resource_state, resource_id: @resource.id)
        @resource.update(current_resource_state_id: @resource_state.id)
        @version = create(:version, resource_id: @resource.id)

        # @curation_activity = create(:curation_activity)
        # @curation_activity.update(identifier_id: @identifier.id)
        @mock_idgen = double('idgen')
        allow(@mock_idgen).to receive('update_identifier_metadata!'.intern).and_raise('submitted DOI')
        allow(Stash::Doi::IdGen).to receive(:make_instance).and_return(@mock_idgen)
      end

      it 'submits when created/changed if it is Published, is versioned and is in Merritt' do
        submitted = false
        begin
          CurationActivity.create(identifier_id: @identifier.id, status: 'Published')
        rescue RuntimeError => ex
          expect(ex.to_s).to eq('submitted DOI')
          submitted = true
        end
        expect(submitted).to eq(true)
      end

      it "doesn't submit when a status besides Embargoed or Published is set" do
        submitted = false
        begin
          CurationActivity.create(identifier_id: @identifier.id, status: 'Curation')
        rescue RuntimeError => ex
          expect(ex.to_s).to eq('submitted DOI')
          submitted = true
        end
        expect(submitted).to eq(false)
      end

      it "doesn't submit when status isn't changed" do
        CurationActivity.skip_callback(:create, :after, :submit_to_datacite)
        item = CurationActivity.create(identifier_id: @identifier.id, status: 'Published')
        CurationActivity.set_callback(:create, :after, :submit_to_datacite)
        submitted = false
        begin
          item.update(status: 'Published')
        rescue RuntimeError => ex
          expect(ex.to_s).to eq('submitted DOI')
          submitted = true
        end
        expect(submitted).to eq(false)
      end

      it "doesn't submit if never sent to Merritt" do
        @resource_state.update(resource_state: 'in_progress')
        submitted = false
        begin
          CurationActivity.create(identifier_id: @identifier.id, status: 'Published')
        rescue RuntimeError => ex
          expect(ex.to_s).to eq('submitted DOI')
          submitted = true
        end
        expect(submitted).to eq(false)
      end

      it "doesn't submit if no version number" do
        @version.update!(version: nil, merritt_version: nil)
        my_cur = CurationActivity.create(identifier_id: @identifier.id, status: 'Unsubmitted')
        # this is kind of crazy, but doing without nesting somehow caches everything and can't get it to update in test
        my_cur.stash_identifier.resources.first.stash_version.update(version: nil, merritt_version: nil)
        submitted = false
        begin
          my_cur.update(status: 'Published')
        rescue RuntimeError => ex
          expect(ex.to_s).to eq('submitted DOI')
          submitted = true
        end
        expect(submitted).to eq(false)
      end

      it "doesn't submit non-production (test) identifiers after first version" do
        @resource2 = create(:resource, identifier_id: @identifier.id)
        @resource_state2 = create(:resource_state, resource_id: @resource2.id)
        @resource2.update(current_resource_state_id: @resource_state2.id)
        @version2 = create(:version, resource_id: @resource2.id, version: 2, merritt_version: 2)
        submitted = false
        begin
          CurationActivity.create(identifier_id: @identifier.id, status: 'Published')
        rescue RuntimeError => ex
          expect(ex.to_s).to eq('submitted DOI')
          submitted = true
        end
        expect(submitted).to eq(false)
      end
    end
  end
end
