require 'ostruct'
require_relative '../../lib/tasks/dash_updater'
require_relative '../../stash/spec_helpers/factory_helper'
require 'byebug'

describe 'datacite_target:update_dash', type: :task do

  before(:each) do
    @identifier = create(:identifier)
    @resource = create(:resource, identifier_id: @identifier.id, meta_view: true)
    @curation_activity = create(:curation_activity, resource: @resource)
  end

  it 'retries failing requests and fails after too many retries' do
    @mock_datacitegen = double('datacitegen')
    allow(@mock_datacitegen).to receive(:update_identifier_metadata!).and_raise(Stash::Doi::DataciteGenError, 'test exception')
    allow(Stash::Doi::DataciteGen).to receive(:new).and_return(@mock_datacitegen)

    expect { Tasks::DashUpdater.submit_id_metadata(stash_identifier: @identifier, retry_pause: 0) }
      .to raise_error(Stash::Doi::DataciteGenError, 'test exception')
  end

  it "returns early if this resource doesn't have a public version" do
    @resource.update(meta_view: false)
    @resource.reload
    expect(Tasks::DashUpdater.submit_id_metadata(stash_identifier: @identifier, retry_pause: 0)).to eq(nil)
  end

end
