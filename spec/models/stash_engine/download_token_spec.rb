require 'rails_helper'

module StashEngine
  RSpec.describe DownloadToken, type: :model do

    before(:each) do
      @resource = create(:resource)
      @download_token = create(:download_token, resource_id: @resource.id)
    end

    describe '#availability_delay_seconds' do

      # not sure this is honestly used
      it 'returns 0 if availability nil' do
        @download_token.available = nil
        expect(@download_token.availability_delay_seconds).to eq(0)
      end

      it 'returns 60 if availability has passed (and status still says unavailable elsewhere)' do
        @download_token.available = Time.new - 25.seconds.to_i
        expect(@download_token.availability_delay_seconds).to eq(60)
      end

      it 'returns estimate if availability in future' do
        @download_token.available = Time.new + 60.seconds.to_i
        expect(@download_token.availability_delay_seconds).to be_within(10).of(60)
      end
    end
  end
end
