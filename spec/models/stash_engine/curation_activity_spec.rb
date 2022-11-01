require 'ostruct'
require_relative '../../../stash/spec_helpers/factory_helper'
require 'byebug'

module StashEngine
  RSpec.describe CurationActivity do

    include Mocks::RSolr
    include Mocks::Stripe

    before(:each) do
      allow_any_instance_of(StashEngine::CurationActivity).to receive(:copy_to_zenodo).and_return(true)
      mock_solr!
      mock_stripe!
    end

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
        allow(@mock_idgen).to receive(:update_identifier_metadata!).and_raise('submitted DOI')
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
        @resource_state = create(:resource_state, :submitted, resource_id: @resource.id)
        @resource.update(current_resource_state_id: @resource_state.id)
        @version = create(:version, resource_id: @resource.id)

        @mock_idgen = spy('idgen')
        allow(@mock_idgen).to receive(:update_identifier_metadata!) # .and_return('called make metadata')
        allow(Stash::Doi::IdGen).to receive(:make_instance).and_return(@mock_idgen)

        @curation_activity1 = create(:curation_activity, resource: @resource)
      end

      it 'does submit when Published is set' do
        create(:curation_activity, resource_id: @resource.id, status: 'published')
        expect(@mock_idgen).to have_received(:update_identifier_metadata!)
      end

      it "doesn't submit when a status besides Embargoed or Published is set" do
        CurationActivity.create(resource_id: @resource.id, status: 'curation')
        expect(@mock_idgen).to_not have_received(:update_identifier_metadata!)
      end

      it "doesn't submit when status isn't changed" do
        @curation_activity2 = create(:curation_activity, resource: @resource, status: 'published')
        expect(@mock_idgen).to have_received(:update_identifier_metadata!).once
        CurationActivity.create(resource_id: @resource.id, status: 'published')
        expect(@mock_idgen).to have_received(:update_identifier_metadata!).once # should not be called for the second 'published'

      end

      it "doesn't submit if never sent to Merritt" do
        @resource_state.update(resource_state: 'in_progress')
        CurationActivity.create(resource_id: @resource.id, status: 'published')
        expect(@mock_idgen).to_not have_received(:update_identifier_metadata!)
      end

      it "doesn't submit if no version number" do
        @version.update!(version: nil, merritt_version: nil)
        CurationActivity.create(resource_id: @resource.id, status: 'published')
        expect(@mock_idgen).to_not have_received(:update_identifier_metadata!)
      end

      it "doesn't submit non-production (test) identifiers after first version" do
        @resource2 = create(:resource, identifier_id: @identifier.id)
        @resource_state2 = create(:resource_state, resource_id: @resource2.id)
        @version2 = create(:version, resource_id: @resource2.id, version: 2, merritt_version: 2)
        CurationActivity.create(resource: @resource2, status: 'published')
        expect(@mock_idgen).to_not have_received(:update_identifier_metadata!)
      end
    end

    describe 'Datacite and EzId failures are properly handled' do
      before(:each) do
        @user = create(:user, first_name: 'Test', last_name: 'User', email: 'test.user@example.org')
        @identifier = create(:identifier)
        @resource = create(:resource, identifier_id: @identifier.id, user: @user)

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
        expect { create(:curation_activity, resource_id: @resource.id, status: 'embargoed') }.to raise_error(Stash::Doi::IdGenError)
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
        @curation_activity2 = create(:curation_activity, status: :embargoed, resource: @resource,
                                                         note: 'We need more about cats')
        expect(@curation_activity2.latest_curation_status_changed?).to be false
      end
    end

    describe '#copy_to_zenodo' do
      before(:each) do
        # this this back to the original method
        allow_any_instance_of(StashEngine::CurationActivity).to receive(:copy_to_zenodo).and_call_original
        @user = create(:user)
        @identifier = create(:identifier)
        @resource = create(:resource, identifier_id: @identifier.id)
        @curation_activity = create(:curation_activity, resource: @resource)
      end

      it 'calls three zenodo methods to copy software, supplemental and data (3rd copy)' do
        expect(@resource).to receive(:send_to_zenodo).and_return('test1')
        expect(@resource).to receive(:send_software_to_zenodo).with(publish: true).and_return('test2')
        expect(@resource).to receive(:send_supp_to_zenodo).with(publish: true).and_return('test3')
        @curation_activity.copy_to_zenodo
      end
    end

    describe 'self.allowed_states(current_state)' do
      it 'indicates the states that are allowed from each' do
        expect(CurationActivity.allowed_states('curation')).to \
          eq(%w[peer_review curation action_required withdrawn embargoed published])

        expect(CurationActivity.allowed_states('withdrawn')).to \
          eq(%w[withdrawn curation])
      end
    end

  end
end
