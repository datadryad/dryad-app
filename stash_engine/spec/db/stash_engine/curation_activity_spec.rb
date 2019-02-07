require 'db_spec_helper'

module StashEngine
  describe CurationActivity do

    before(:each) do
      @identifier = StashEngine::Identifier.create(identifier_type: 'DOI', identifier: '10.123/123')
      @resource = StashEngine::Resource.create(identifier_id: @identifier.id)
    end

    context :new do
      it 'defaults status to :in_progress' do
        activity = CurationActivity.new(resource: @resource)
        expect(activity.status).to eql('in_progress')
      end

      it 'requires a resource' do
        activity = CurationActivity.new(resource: nil)
        expect(activity.valid?).to eql(false)
      end
    end

    context :latest do
      before(:each) do
        @ca = CurationActivity.create(resource_id: @resource.id)
      end

      it 'returns the most recent activity' do
        ca2 = CurationActivity.create(resource_id: @resource.id, status: 'peer_review')
        expect(CurationActivity.latest(@resource)).to eql(ca2)
      end

      it 'it ignores unchanged statuses' do
        CurationActivity.create(resource_id: @resource.id, status: 'unchanged')
        expect(CurationActivity.latest(@resource)).to eql(@ca)
      end
    end

    context :readable_status do
      before(:each) do
        @ca = CurationActivity.create(resource_id: @resource.id)
      end

      it 'returns a readable version of :peer_review' do
        @ca.peer_review!
        expect(@ca.readable_status).to eql('Private for Peer Review')
      end

      it 'returns a readable version of :action_required' do
        @ca.action_required!
        expect(@ca.readable_status).to eql('Author Action Required')
      end

      it 'returns a readable version of :unchanged' do
        @ca.unchanged!
        expect(@ca.readable_status).to eql('Status Unchanged')
      end

      it 'returns a default readable version of the remaining statuses' do
        CurationActivity.statuses.each do |s|
          unless %w[peer_review action_required unchanged].include?(s)
            @ca.send("#{s}!")
            expect(@ca.readable_status).to eql(s.humanize)
          end
        end
      end
    end

    context :callbacks do
      it 'calls submit_to_stripe method after creating a new CurationActivity' do
        ca = CurationActivity.new(resource_id: @resource.id)
        expect(ca).to receive(:submit_to_stripe)
        ca.save
      end

      it 'calls submit_to_stripe method after updating a CurationActivity' do
        ca = CurationActivity.create(resource_id: @resource.id)
        expect(ca).to receive(:submit_to_stripe)
        ca.update(status: CurationActivity.curation)
      end

      it 'calls submit_to_datacite method after creating a new CurationActivity' do
        ca = CurationActivity.new(resource_id: @resource.id)
        expect(ca).to receive(:submit_to_datacite)
        ca.save
      end

      it 'calls submit_to_datacite method after updating a CurationActivity' do
        ca = CurationActivity.create(resource_id: @resource.id)
        expect(ca).to receive(:submit_to_datacite)
        ca.update(status: CurationActivity.curation)
      end
    end

  end
end
