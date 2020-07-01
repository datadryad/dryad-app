require 'rails_helper'

module StashEngine

  RSpec.describe Resource, type: :model do

    context 'peer_review' do

      describe :requires_peer_review? do
        let!(:resource) { create(:resource, identifier: create(:identifier)) }

        it 'returns false if hold_for_peer_review flag is not set' do
          expect(resource.send(:hold_for_peer_review?)).to eql(false)
        end
        it 'returns true if hold_for_peer_review flag is set' do
          resource.hold_for_peer_review = true
          expect(resource.send(:hold_for_peer_review?)).to eql(true)
        end
        it 'returns false if hold_for_peer_review flag is not set and there is no publication defined' do
          expect(resource.send(:hold_for_peer_review?)).to eql(false)
        end
      end

      describe :send_software_to_zenodo do
        before(:each) do
          @resource = create(:resource, identifier: create(:identifier))
          @identifier = @resource.identifier
          @resource.software_uploads << create(:software_upload)
        end

        it 'sends the software to zenodo' do
          expect(@identifier).to receive(:'has_zenodo_software?').and_call_original
          expect(StashEngine::ZenodoSoftwareJob).to receive(:perform_later)
          @resource.send_software_to_zenodo
          copy_record = @resource.zenodo_copies.software.first
          expect(copy_record.resource_id).to eq(@resource.id)
          expect(copy_record.state).to eq('enqueued')
        end
      end

    end
  end
end
