require 'db_spec_helper'

module StashEngine
  describe CurationActivity do

    before(:each) do
      @identifier = StashEngine::Identifier.create(identifier_type: 'DOI', identifier: '10.123/123')
      @resource = StashEngine::Resource.create(identifier_id: @identifier.id)
      # reload so that it picks up any associated models that are initialized
      # (e.g. CurationActivity and ResourceState)
      @resource.reload
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
    end

    context :readable_status do
      before(:each) do
        @ca = CurationActivity.create(resource_id: @resource.id)
      end

      it 'class method allows conversion of status to humanized status' do
        expect(CurationActivity.readable_status('submitted')).to eql('Submitted')
      end

      it 'returns a readable version of :peer_review' do
        @ca.peer_review!
        expect(@ca.readable_status).to eql('Private for Peer Review')
      end

      it 'returns a readable version of :action_required' do
        @ca.action_required!
        expect(@ca.readable_status).to eql('Author Action Required')
      end

      it 'returns a default readable version of the remaining statuses' do
        CurationActivity.statuses.each do |s|
          unless %w[peer_review action_required unchanged].include?(s)
            @ca.send("#{s}!")
            expect(@ca.readable_status).to eql(s.humanize.split.map(&:capitalize).join(' '))
          end
        end
      end
    end

    context :callbacks do

      before(:each) do
        allow_any_instance_of(StashEngine::Resource).to receive(:submit_to_solr).and_return(true)
      end

      it 'updates the resources.current_curation_activity_id when creating a new record' do
        ca = CurationActivity.create(resource_id: @resource.id)
        expect(@resource.reload.current_curation_activity_id).to eql(ca.id)
      end

      it 'updates the resources.current_curation_activity_id to the prior curation activity when the record is removed' do
        original = @resource.current_curation_activity_id
        ca = CurationActivity.create(resource_id: @resource.id, status: 'submitted')

        ca.destroy
        expect(@resource.reload.current_curation_activity_id).to eql(original)
      end

      it 'removes the resources.current_curation_activity_id when the record is deleted and no prior curation activity exists' do
        @resource.current_curation_activity.destroy
        expect(@resource.reload.current_curation_activity_id).to eql(nil)
      end

      it 'calls submit_to_stripe method after creating a CurationActivity with a status of published' do
        ca = CurationActivity.create(resource_id: @resource.id, status: 'published')
        expect(ca).to receive(:submit_to_stripe)
        ca.update(status: 'curation')
      end

      it 'calls submit_to_datacite method after creating a new CurationActivity with a status of published' do
        ca = CurationActivity.new(resource_id: @resource.id, status: 'published')
        expect(ca).to receive(:submit_to_datacite)
        ca.save
      end

      it 'does not call submit_to_stripe method after creating a CurationActivity when its not published ' do
        ca = CurationActivity.create(resource_id: @resource.id, status: 'curation')
        expect(ca).not_to receive(:submit_to_stripe)
        ca.save
      end

      it 'does not call submit_to_datacite method after creating a new CurationActivity when its not published' do
        ca = CurationActivity.new(resource_id: @resource.id, status: 'action_required')
        expect(ca).not_to receive(:submit_to_datacite)
        ca.save
      end
    end

  end
end
