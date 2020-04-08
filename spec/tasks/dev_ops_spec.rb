require 'rails_helper'
require 'byebug'

describe 'dev_ops:retry_zenodo_errors', type: :task do
  it 'preloads the Rails environment' do
    expect(task.prerequisites).to include 'environment'
  end

  it 'logs to stdout' do
    expect { task.execute }.to output(/Re-enqueuing errored ZenodoCopies/).to_stdout
  end

  describe 'selects the errored ones' do
    before(:each) do
      @zc1 = create(:zenodo_copy, state: 'error', retries: 5)
      @zc2 = create(:zenodo_copy, state: 'error', retries: 0)
      allow(StashEngine::ZenodoCopyJob).to receive(:perform_later).and_return(nil)
    end

    it 'only processes ones with less than 4 retries' do
      expect { task.execute }.to output(/Adding resource_id: #{@zc2.resource_id}/).to_stdout
      @zc1.reload
      @zc2.reload
      expect(@zc2.state).to eq('enqueued')
      expect(@zc1.state).to eq('error')
    end
  end
end
