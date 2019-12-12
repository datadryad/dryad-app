require 'spec_helper'
require 'db_spec_helper'
require 'ostruct'
require_relative '../../../../lib/tasks/datacite_target/dash_updater.rb'
require_relative '../../../../../spec_helpers/factory_helper'
require 'byebug'

module DashUpdater
  describe 'Updating Function' do

    before(:each) do
      @identifier = create(:identifier)
      @resource = create(:resource, identifier_id: @identifier.id, meta_view: true)
      @curation_activity = create(:curation_activity, resource: @resource)
    end

    it 'retries failing requests and fails after too many retries' do
      @mock_idgen = double('idgen')
      allow(@mock_idgen).to receive('update_identifier_metadata!'.intern).and_raise(Stash::Doi::IdGenError, 'test exception')
      allow(Stash::Doi::IdGen).to receive(:make_instance).and_return(@mock_idgen)

      expect { DashUpdater.submit_id_metadata(stash_identifier: @identifier, retry_pause: 0) }
        .to raise_error(Stash::Doi::IdGenError, 'test exception')
    end

    it "returns early if this resource doesn't have a public version" do
      @resource.update(meta_view: false)
      @resource.reload
      expect(DashUpdater.submit_id_metadata(stash_identifier: @identifier, retry_pause: 0)).to eq(nil)
    end
  end
end
