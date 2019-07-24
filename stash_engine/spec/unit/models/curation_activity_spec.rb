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
        @resource = create(:resource, identifier_id: @identifier.id)
        @curation_activity = create(:curation_activity, resource: @resource)
        @mock_idgen = double('idgen')
        allow(@mock_idgen).to receive('update_identifier_metadata!'.intern).and_raise('submitted DOI')
        allow(Stash::Doi::IdGen).to receive(:make_instance).and_return(@mock_idgen)
      end

      it 'shows the appropriate dataset identifier' do
        expect(@curation_activity.resource.identifier.to_s).to eq(@identifier.to_s)
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
        @mock_idgen = spy('idgen')
        # allow(@mock_idgen).to receive('update_identifier_metadata!'.intern).and_raise('submitted DOI')
        allow(@mock_idgen).to receive('update_identifier_metadata!'.intern) # .and_return('called make metadata')
        allow(Stash::Doi::IdGen).to receive(:make_instance).and_return(@mock_idgen)

        # get rid of callbacks for adding one and testing
        CurationActivity.skip_callback(:create, :after, :submit_to_datacite)
        CurationActivity.skip_callback(:create, :after, :update_solr)
        CurationActivity.skip_callback(:save, :after, :submit_to_stripe)
        @curation_activity1 = create(:curation_activity, resource: @resource)
        CurationActivity.set_callback(:create, :after, :submit_to_datacite)
        # these two never need to fire to test this example
        # CurationActivity.set_callback(:create, :after, :update_solr)
        # CurationActivity.set_callback(:save, :after, :submit_to_stripe)
      end

      it "doesn't submit when a status besides Embargoed or Published is set" do
        CurationActivity.create(resource_id: @resource.id, status: 'curation')
        expect(@mock_idgen).to_not have_received(:update_identifier_metadata)
      end

      it "doesn't submit when status isn't changed" do
        CurationActivity.skip_callback(:create, :after, :submit_to_datacite, :submit_to_stripe)
        @curation_activity2 = create(:curation_activity, resource: @resource, status: 'published')
        CurationActivity.set_callback(:create, :after, :submit_to_datacite)

        CurationActivity.create(resource_id: @resource.id, status: 'published')
        expect(@mock_idgen).to_not have_received(:update_identifier_metadata)
      end

      it "doesn't submit if never sent to Merritt" do
        @resource_state.update(resource_state: 'in_progress')
        CurationActivity.create(resource_id: @resource.id, status: 'published')
        expect(@mock_idgen).to_not have_received(:update_identifier_metadata)
      end

      it "doesn't submit if no version number" do
        @version.update!(version: nil, merritt_version: nil)
        CurationActivity.create(resource_id: @resource.id, status: 'published')
        expect(@mock_idgen).to_not have_received(:update_identifier_metadata)
      end

      it "doesn't submit non-production (test) identifiers after first version" do
        @resource2 = create(:resource, identifier_id: @identifier.id)
        @resource_state2 = create(:resource_state, resource_id: @resource2.id)
        @version2 = create(:version, resource_id: @resource2.id, version: 2, merritt_version: 2)
        CurationActivity.skip_callback(:create, :after, :submit_to_datacite)
        CurationActivity.create(resource: @resource2, status: 'published')
        CurationActivity.set_callback(:create, :after, :submit_to_datacite)
        expect(@mock_idgen).to_not have_received(:update_identifier_metadata)
      end
    end

    describe 'Datacite and EzId failures are properly handled' do
      before(:each) do
        @user = create(:user, first_name: 'Test', last_name: 'User', email: 'test.user@example.org')
        @identifier = create(:identifier)
        @resource = create(:resource, identifier_id: @identifier.id, user: @user)

        CurationActivity.skip_callback(:create, :after, :update_solr)
        CurationActivity.skip_callback(:save, :after, :submit_to_stripe)
        allow_any_instance_of(CurationActivity).to receive(:should_update_doi?).and_return(true)

        logger = double(ActiveSupport::Logger)
        allow(logger).to receive(:error).with(any_args).and_return(true)
        allow(Rails).to receive(:logger).and_return(logger)

        allow_any_instance_of(ActionMailer::MessageDelivery).to receive(:deliver_now)
      end

      it 'catches errors and emails the admins' do
        dc_error = Stash::Doi::IdGenError.new('Testing errors')
        allow(Stash::Doi::IdGen).to receive(:make_instance).with(any_args).and_raise(dc_error)

        message = instance_double(ActionMailer::MessageDelivery)
        expect(StashEngine::UserMailer).to receive(:error_report).with(any_args).and_return(message)
        expect(message).to receive(:deliver_now)
        expect { CurationActivity.create(resource_id: @resource.id, status: 'embargoed') }.to raise_error(Stash::Doi::IdGenError)
      end
    end

    describe '#latest_curation_status_changed?' do

      before(:each) do
        @user = create(:user)
        @identifier = create(:identifier)
        @resource = create(:resource, identifier_id: @identifier.id)
      end

      it 'considers things changed if there is only one curation status for this resource' do
        StashEngine::CurationActivity.destroy_all
        @curation_activity = create(:curation_activity, resource: @resource)
        expect(@curation_activity.latest_curation_status_changed?).to be true
      end

      it 'considers changed to be true if the last two curation statuses are unequal' do
        @curation_activity1 = create(:curation_activity, status: 'in_progress', resource: @resource)
        @curation_activity2 = create(:curation_activity, status: 'embargoed', resource: @resource)
        expect(@curation_activity2.latest_curation_status_changed?).to be true
      end

      it 'considers changed to be false if the last two curation statuses are equal' do
        @curation_activity1 = create(:curation_activity, status: :embargoed, resource: @resource)
        @curation_activity2 = create(:curation_activity, status: :embargoed, resource: @resource, note: 'We need more about cats')
        expect(@curation_activity2.latest_curation_status_changed?).to be false
      end
    end
  end
end
