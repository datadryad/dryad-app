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

    describe 'available_in_merritt?' do
      it 'returns false if merritt_object_info returns no response' do
        @states[2].destroy!
        @identifier = @resources[0].identifier
        allow(@identifier).to receive(:merritt_object_info).and_return({})
        allow(@resources[0]).to receive(:identifier).and_return(@identifier)
        allow(@states[1]).to receive(:resource).and_return(@resources[0])

        expect(@states[1].available_in_merritt?).to eql(false)
      end

      it 'returns true if the version exists in the returned data' do
        @states[2].destroy!
        @identifier = @resources[0].identifier
        allow(@identifier).to receive(:merritt_object_info).and_return(
            JSON.parse(File.read(Rails.root.join('spec/fixtures/merritt_local_id_search_response.json'))))
        allow(@resources[0]).to receive(:identifier).and_return(@identifier)
        allow(@states[1]).to receive(:resource).and_return(@resources[0])

        expect(@states[1].available_in_merritt?).to eql(true)
      end

      it 'returns false if the version does not exist in the returned data' do
        @states[2].destroy!
        @identifier = @resources[0].identifier
        allow(@identifier).to receive(:merritt_object_info).and_return(
          JSON.parse(File.read(Rails.root.join('spec/fixtures/merritt_local_id_search_response.json'))))
        allow(@resources[0]).to receive(:identifier).and_return(@identifier)
        allow(@states[1]).to receive(:resource).and_return(@resources[0])

        @resources[0].stash_version.update(merritt_version: 4)

        expect(@states[1].available_in_merritt?).to eql(false)
      end
    end

    describe 'set_as_completed' do

    end
  end
end
