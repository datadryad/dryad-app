require 'rails_helper'

RSpec.describe PublicationJob, type: :job do
  include Mocks::Datacite
  include Mocks::CurationActivity

  let(:identifier) { create(:identifier) }
  let(:user) { create(:user) }
  let(:curator) { create(:user, role: 'curator') }
  let(:resource) { create(:resource, :submitted, user: user, identifier: identifier) }
  let(:status) { 'published' }

  subject { PublicationJob }

  before(:each) do
    neuter_emails!
    mock_datacite_gen!
    allow(Sidekiq).to receive(:redis).and_yield(double('Redis', decr: 0))
  end

  context :submit_to_datacite do
    it 'does submit when Published is set' do
      activity = CurationService.new(resource: resource, user: curator, status: status).process
      subject.new.perform(activity.id)
      expect(@mock_datacitegen).to have_received(:update_identifier_metadata!)
    end

    it "doesn't submit when a status besides Embargoed or Published is set" do
      activity = CurationService.new(resource: resource, user: curator, status: 'to_be_published').process
      subject.new.perform(activity.id)
      expect(@mock_datacitegen).to_not have_received(:update_identifier_metadata!)
    end

    it "doesn't submit if never sent to repo" do
      resource.current_resource_state.update(resource_state: 'in_progress')
      activity = CurationService.new(resource: resource, user: curator, status: status).process
      subject.new.perform(activity.id)
      expect(@mock_datacitegen).to_not have_received(:update_identifier_metadata!)
    end

    it "doesn't submit if no version number" do
      resource.stash_version.update!(version: nil, merritt_version: nil)
      activity = CurationService.new(resource: resource, user: curator, status: status).process
      subject.new.perform(activity.id)
      expect(@mock_datacitegen).to_not have_received(:update_identifier_metadata!)
    end
  end
end
