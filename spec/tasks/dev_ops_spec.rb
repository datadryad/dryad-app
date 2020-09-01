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
      ident = create(:identifier)
      ident2 = create(:identifier)
      @zc1 = create(:zenodo_copy, state: 'error', retries: 5, identifier_id: ident.id)
      @zc2 = create(:zenodo_copy, state: 'error', retries: 0, identifier_id: ident2.id)
      allow(StashEngine::ZenodoCopyJob).to receive(:perform_later).and_return(nil)
    end

    it 'only processes ones with less than 4 retries (zenodo_copy)' do
      expect { task.execute }.to output(/Adding resource_id: #{@zc2.resource_id}/).to_stdout
      @zc1.reload
      @zc2.reload
      expect(@zc2.state).to eq('enqueued')
      expect(@zc1.state).to eq('error')
    end

    it 'processes ones with less than 4 retries (zenodo software)' do
      @zc1.update(copy_type: 'software')
      @zc2.update(copy_type: 'software')
      expect { task.execute }.to output(/Adding resource_id: #{@zc2.resource_id}/).to_stdout
      @zc1.reload
      @zc2.reload
      expect(@zc2.state).to eq('enqueued')
      expect(@zc1.state).to eq('error')
    end
  end
end

describe 'dev_ops:long_jobs', type: :task do

  it 'detects no jobs if none in interesting states' do
    create(:repo_queue_state, state: 'completed')
    ident = create(:identifier)
    create(:zenodo_copy, state: 'finished', identifier_id: ident.id)
    expect { task.execute }.to output(/0\sitems\sin\sMerritt.+
      0\sitems\sare\sbeing\ssent\sto\sMerritt.+
      0\sitems\sin\sZenodo.+
      0\sitems\sare\sstill\sbeing\sreplicated\sto\sZenodo/xm).to_stdout
  end

  it 'detects Merritt queued and executing' do
    create(:repo_queue_state, state: 'enqueued')
    create(:repo_queue_state, state: 'processing')
    expect { task.execute }.to output(/1\sitems\sin\sMerritt.+
      1\sitems\sare\sbeing\ssent\sto\sMerritt.+/xm).to_stdout
  end

  it 'detects zenodo queued and executing' do
    ident = create(:identifier)
    ident2 = create(:identifier)
    create(:zenodo_copy, state: 'enqueued', identifier_id: ident.id)
    create(:zenodo_copy, state: 'replicating', identifier_id: ident2.id)
    expect { task.execute }.to output(/1\sitems\sin\sZenodo.+
      1\sitems\sare\sstill\sbeing\sreplicated\sto\sZenodo/xm).to_stdout
  end

end

describe 'dev_ops:get_counter_token', type: :task do
  it 'gets the counter token from our config and outputs it as the last line' do
    expect { task.execute }.to output(/#{APP_CONFIG[:counter][:token]}/).to_stdout
  end
end
