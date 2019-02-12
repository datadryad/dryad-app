require 'db_spec_helper'

module StashEngine
  describe ResourceState do

    before(:each) do
      @identifier = StashEngine::Identifier.create(identifier_type: 'DOI', identifier: '10.123/123')
      @resource = StashEngine::Resource.create(identifier_id: @identifier.id)
    end

    context :callbacks do

      it 'creates a CurationActivity when resource_state is "submitted"' do
        original = @resource.current_resource_state
        original.update(resource_state: 'submitted')
        @resource.reload
        expect(@resource.curation_activities.length).to eql(2)
        expect(@resource.current_curation_status).to eql('submitted')
      end

      it 'creates a CurationActivity when the resource_state is "in_progress"' do
        original = @resource.current_resource_state
        original.update(resource_state: 'submitted')
        ResourceState.create(resource_id: @resource.id, resource_state: 'in_progress')
        @resource.reload
        expect(@resource.curation_activities.length).to eql(3)
        expect(@resource.current_curation_status).to eql('in_progress')
      end

      it 'cadoes NOT create a CurationActivity record when resource_state is "error" or "processing"' do
        original = @resource.current_resource_state
        original.update(resource_state: 'error')
        @resource.reload
        expect(@resource.curation_activities.length).to eql(1)
        expect(@resource.current_curation_status).to eql('in_progress')

        original = @resource.current_resource_state
        original.update(resource_state: 'processing')
        @resource.reload
        expect(@resource.curation_activities.length).to eql(1)
        expect(@resource.current_curation_status).to eql('in_progress')
      end

    end

  end
end
