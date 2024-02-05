# == Schema Information
#
# Table name: stash_engine_repo_queue_states
#
#  id          :integer          not null, primary key
#  resource_id :integer
#  state       :string
#  hostname    :string(191)
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
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
        allow(@resource).to receive(:identifier).and_return(@identifier)
        allow(@states[1]).to receive(:resource).and_return(@resource)
        allow(@states[1]).to receive(:available_in_storage?).and_return(true)

        expect(::StashEngine.repository).to receive(:cleanup_files).with(@resource).and_return(true)
        expect(@states[1].possibly_set_as_completed).to eql(true)
      end

    end
  end
end
