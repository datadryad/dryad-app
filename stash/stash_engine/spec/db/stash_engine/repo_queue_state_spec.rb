require 'db_spec_helper'

module StashEngine
  describe User do
    attr_reader :user

    before(:each) do
      @resources = [create(:resource), create(:resource)]
      @states = [create(:repo_queue_state, resource_id: @resources[0].id, state: 'enqueued', hostname: 'localhost'),
                 create(:repo_queue_state, resource_id: @resources[0].id, state: 'processing', hostname: 'localhost'),
                 create(:repo_queue_state, resource_id: @resources[0].id, state: 'completed', hostname: 'localhost'),
                 create(:repo_queue_state, resource_id: @resources[1].id, state: 'enqueued', hostname: 'localhost'),
                 create(:repo_queue_state, resource_id: @resources[1].id, state: 'processing', hostname: 'localhost'),
                 create(:repo_queue_state, resource_id: @resources[1].id, state: 'errored', hostname: 'localhost')]

    end

    describe 'self#latest_per_resource' do
      it 'returns the two latest states for the two resources' do
        results = RepoQueueState.latest_per_resource
        expect(results.first).to eq(@states[2])
        expect(results.second).to eq(@states[5])
      end
    end

    describe 'self#latest' do
      it 'gets the latest for a single resource' do
        result = RepoQueueState.latest(resource_id: @resources.second.id)
        expect(result).to eq(@states[-1])
      end
    end
  end
end
