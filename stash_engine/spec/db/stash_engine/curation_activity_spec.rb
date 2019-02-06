require 'db_spec_helper'

module StashEngine
  describe CurationActivity do

    before(:each) do
      @identifier = StashEngine::Identifier.create(identifier_type: 'DOI', identifier: '10.123/123')
      @resource = StashEngine::Resource.create(identifier_id: @identifier.id)
    end

    context :new do
      it 'defaults status to :in_progress' do
        activity = CurationActivity.new(identifier: @identifier, resource: @resource)
        expect(activity.status).to eql('in_progress')
      end

      it 'requires an identifier' do
        activity = CurationActivity.new(resource: @resource)
        expect(activity.valid?).to eql(false)
      end

      it 'requires a resource' do
        activity = CurationActivity.new(identifier: @identifier)
        expect(activity.valid?).to eql(false)
      end
    end

    context :readable_status do
      before(:each) do
        @ca = CurationActivity.create(identifier_id: @identifier.id, resource_id: @resource.id)
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
        CurationActivity.statuses.keys.each do |s|
          unless %w[peer_review action_required unchanged].include?(s)
            @ca.send("#{s}!")
            expect(@ca.readable_status).to eql(s.humanize)
          end
        end
      end
    end

    context :callbacks do
      it 'calls submit_to_stripe method after creating a new CurationActivity' do
        ca = CurationActivity.new(identifier_id: @identifier.id, resource_id: @resource.id)
        expect(ca).to receive(:submit_to_stripe)
        ca.save
      end

      it 'calls submit_to_stripe method after updating a CurationActivity' do
        ca = CurationActivity.create(identifier_id: @identifier.id, resource_id: @resource.id)
        expect(ca).to receive(:submit_to_stripe)
        ca.update(status: CurationActivity.curation)
      end

      it 'calls submit_to_datacite method after creating a new CurationActivity' do
        ca = CurationActivity.new(identifier_id: @identifier.id, resource_id: @resource.id)
        expect(ca).to receive(:submit_to_datacite)
        ca.save
      end

      it 'calls submit_to_datacite method after updating a CurationActivity' do
        ca = CurationActivity.create(identifier_id: @identifier.id, resource_id: @resource.id)
        expect(ca).to receive(:submit_to_datacite)
        ca.update(status: CurationActivity.curation)
      end
    end

  end
end
