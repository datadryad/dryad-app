# == Schema Information
#
# Table name: stash_engine_repo_queue_states
#
#  id          :integer          not null, primary key
#  hostname    :string(191)
#  state       :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  resource_id :integer
#
# Indexes
#
#  index_stash_engine_repo_queue_states_on_resource_id  (resource_id)
#  index_stash_engine_repo_queue_states_on_state        (state)
#
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

    describe 'possibly_set_as_completed' do

      before(:each) do
        @states[2].destroy!
        @resource = @resources[0]
        @identifier = @resource.identifier
      end

      # "not complete" case is tested more thoroughly above already
      it "returns false if it isn't done yet" do
        allow(@resource).to receive(:identifier).and_return(@identifier)
        allow(@states[1]).to receive(:resource).and_return(@resource)

        expect(@states[1].possibly_set_as_completed).to eql(false)
      end

      it 'calls the completion methods if it is completed' do
        mock_service = double(Submission::ResourcesService)
        allow(@resource).to receive(:identifier).and_return(@identifier)
        allow(@states[1]).to receive(:resource).and_return(@resource)
        allow(@states[1]).to receive(:available_in_storage?).and_return(true)

        expect(Submission::ResourcesService).to receive(:new).with(@resource.id).and_return(mock_service)
        expect(mock_service).to receive(:finalize).and_return(true)
        expect(mock_service).to receive(:cleanup_files).and_return(true)
        expect(@resource).to receive(:update_repo_queue_state).with({ state: 'completed' }).and_return(true)
        expect(@states[1].possibly_set_as_completed).to eql(true)
      end

    end
  end
end
