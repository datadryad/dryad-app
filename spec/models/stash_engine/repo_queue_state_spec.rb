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

      before(:each) do
        @states[2].destroy!
        @resource = @resources[0]
        @identifier = @resource.identifier
      end

      it 'returns false if merritt_object_info returns no response' do
        allow(@identifier).to receive(:merritt_object_info).and_return({})
        allow(@resource).to receive(:identifier).and_return(@identifier)
        allow(@states[1]).to receive(:resource).and_return(@resource)

        expect(@states[1].available_in_merritt?).to eql(false)
        expect(@states[1].mrt_results).to be_empty
      end

      it 'returns true if the version exists in the returned data' do
        allow(@identifier).to receive(:merritt_object_info).and_return(
            JSON.parse(File.read(Rails.root.join('spec/fixtures/merritt_local_id_search_response.json'))))
        allow(@resource).to receive(:identifier).and_return(@identifier)
        allow(@states[1]).to receive(:resource).and_return(@resource)

        expect(@states[1].available_in_merritt?).to eql(true)
        expect(@states[1].mrt_results).not_to be_empty
      end

      it 'returns false if the version does not exist in the returned data' do
        allow(@identifier).to receive(:merritt_object_info).and_return(
          JSON.parse(File.read(Rails.root.join('spec/fixtures/merritt_local_id_search_response.json'))))
        allow(@resource).to receive(:identifier).and_return(@identifier)
        allow(@states[1]).to receive(:resource).and_return(@resource)

        @resource.stash_version.update(merritt_version: 4)

        expect(@states[1].available_in_merritt?).to eql(false)
        expect(@states[1].mrt_results).not_to be_empty # because there were results but they're not for this version
      end
    end

    describe 'provisional_set_as_completed' do

      before(:each) do
        @states[2].destroy!
        @resource = @resources[0]
        @identifier = @resource.identifier
      end

      # "not complete" case is tested more thoroughly above already
      it "returns false if it isn't done yet" do
        allow(@identifier).to receive(:merritt_object_info).and_return({})
        allow(@resource).to receive(:identifier).and_return(@identifier)
        allow(@states[1]).to receive(:resource).and_return(@resource)

        expect(@states[1].provisional_set_as_completed).to eql(false)
      end

      it "calls the completion methods if it is completed" do
        allow(@identifier).to receive(:merritt_object_info).and_return(
          JSON.parse(File.read(Rails.root.join('spec/fixtures/merritt_local_id_search_response.json'))))
        allow(@resource).to receive(:identifier).and_return(@identifier)
        allow(@states[1]).to receive(:resource).and_return(@resource)

        expect(@states[1]).to receive(:update_size!).and_return(true)
        expect(::StashEngine.repository).to receive(:cleanup_files).with(@resource).and_return(true)
        expect(@states[1].provisional_set_as_completed).to eql(true)
      end


    end
  end
end
