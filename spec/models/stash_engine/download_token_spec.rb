# == Schema Information
#
# Table name: stash_engine_download_tokens
#
#  id          :integer          not null, primary key
#  available   :datetime
#  token       :string(191)
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  resource_id :integer
#
# Indexes
#
#  index_stash_engine_download_tokens_on_token  (token)
#
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
