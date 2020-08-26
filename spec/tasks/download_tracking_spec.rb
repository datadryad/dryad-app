require 'byebug'

describe 'download_tracking:cleanup', type: :task do

  before(:each) do
    @resource = create(:resource)
    @upload = create(:file_upload, resource: @resource)
  end

  it 'preloads the Rails environment' do
    expect(task.prerequisites).to include 'environment'
  end

  it 'logs to stdout' do
    expect { task.execute }.to output(/Finished DownloadHistory cleanup/).to_stdout
  end

  it 'cleans up old entries more than 60 days old' do
    StashEngine::DownloadHistory.create(resource_id: @resource.id, ip_address: '127.0.0.1', created_at: 65.days.ago, file_upload_id: @upload.id)
    StashEngine::DownloadHistory.create(resource_id: @resource.id, ip_address: '127.0.0.1', file_upload_id: @upload.id)
    expect(StashEngine::DownloadHistory.where(resource_id: @resource.id).count).to eq(2)
    expect { task.execute }.to output(/Finished DownloadHistory cleanup/).to_stdout
    # it removed the old one
    expect(StashEngine::DownloadHistory.where(resource_id: @resource.id).count).to eq(1)
  end

  it 'fixes download status for non-updated items more than one day old' do
    StashEngine::DownloadHistory.create(resource_id: @resource.id, ip_address: '127.0.0.1', created_at: 3.days.ago,
                                        state: 'downloading', file_upload_id: @upload.id)
    dlh = StashEngine::DownloadHistory.where(resource_id: @resource.id)
    expect(dlh.count).to eq(1)
    item = dlh.first
    expect(item.state).to eq('downloading')
    expect { task.execute }.to output(/Finished DownloadHistory cleanup/).to_stdout
    item.reload
    expect(item.state).to eq('finished')
  end
end
