require 'rails_helper'

module StashEngine

  RSpec.describe Resource, type: :model do

    context 'peer_review' do

      describe :requires_peer_review? do
        let!(:resource) { create(:resource, identifier: create(:identifier)) }

        it 'returns false if hold_for_peer_review flag is not set' do
          expect(resource.send(:requires_peer_review?)).to eql(false)
        end
        it 'returns true if hold_for_peer_review flag is set' do
          resource.hold_for_peer_review = true
          expect(resource.send(:requires_peer_review?)).to eql(true)
        end
        it 'returns false if hold_for_peer_review flag is not set and there is no publication defined' do
          expect(resource.send(:requires_peer_review?)).to eql(false)
        end
        it 'returns true if hold_for_peer_review flag is not set but there is a publication defined' do
          resource.identifier.internal_data << create(:internal_datum, data_type: 'publicationDOI')
          expect(resource.send(:requires_peer_review?)).to eql(true)
        end

      end

    end

  end

end
