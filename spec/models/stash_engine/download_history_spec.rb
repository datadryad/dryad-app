# Trying to add new models to this area instead of inside 'stash' subdirectories since it's much easier to maintain tests
# inside of here than in the engines.  Also the loading of tests isn't hacked together in some unmaintainable and non-standard
# way like they are inside the engine tests.

require 'rails_helper'

module StashEngine
  RSpec.describe DownloadHistory, type: :model do

    describe :mark_event do
      before(:each) do
        @resource = create(:resource)
        DownloadHistory.mark_start(ip: '168.10.0.1', user_agent: 'HorseStomping Browser', resource_id: @resource.id, file_id: 88)
      end

      it 'adds started downloads to the database' do
        dl_all = DownloadHistory.where(resource_id: @resource.id)
        expect(dl_all.count).to eq(1)
        dlh = dl_all.first
        expect(dlh.ip_address).to eq('168.10.0.1')
        expect(dlh.user_agent).to eq('HorseStomping Browser')
        expect(dlh.state).to eq('downloading')
      end

      it 'modifies finished download to change state and updated_at timestamp' do
        dl_all = DownloadHistory.where(resource_id: @resource.id)
        expect(dl_all.count).to eq(1)
        dlh = dl_all.first
        updated_at_before = dlh.updated_at
        sleep 1 # just to be sure timestamps are different seconds
        DownloadHistory.mark_end(download_history: dlh)
        dlh.reload
        expect(dlh.updated_at).not_to eq(updated_at_before)
        expect(dlh.state).to eq('finished')
      end
    end
  end
end
