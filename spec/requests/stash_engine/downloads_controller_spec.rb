require 'rails_helper'
require_relative 'download_helpers'
require 'byebug'

# see https://relishapp.com/rspec/rspec-rails/v/3-8/docs/request-specs/request-spec
module StashEngine
  RSpec.describe DownloadsController, type: :request do
    include Mocks::Salesforce

    before(:each) do
      mock_salesforce!
      @user = create(:user, role: 'superuser')
      @resource = create(:resource, user_id: @user.id, total_file_size: 0)
      @resource.current_resource_state.update(resource_state: 'submitted')
      @token = create(:download_token, resource_id: @resource.id, available: Time.new + 5.minutes.to_i)
      @resource.reload

      # HACK: in session because requests specs don't allow session in rails 4
      allow_any_instance_of(DownloadsController).to receive(:session).and_return({ user_id: @user.id }.to_ostruct)
    end

    # this ultimately may give a redirect (depends on status)
    describe '#download_resource' do
      it 'is not found' do
        stub_404_status
        stub_404_assemble
        response_code = get "/downloads/download_resource/#{@resource.id}"
        expect(response_code).to eq(404)
        expect(response.body).to include('Download for this dataset is unavailable')
      end

      it 'returns 404 for item where not available because of permissions' do
        # couldn't get 'unstub' to work here for deprecation warnings and other problems, so just redefining it
        allow_any_instance_of(DownloadsController).to receive(:session).and_return({ user_id: nil }.to_ostruct)
        response_code = get "/downloads/download_resource/#{@resource.id}"
        expect(response_code).to eq(404)
        expect(response.body).to include('Download for this dataset is unavailable')
      end

      it 'lets people pass who have the secret sharing link' do
        # couldn't get 'unstub' to work here for deprecation warnings and other problems, so just redefining it
        allow_any_instance_of(DownloadsController).to receive(:session).and_return({ user_id: nil }.to_ostruct)
        share_id = @resource.identifier.shares.first.secret_id
        response_code = get "/downloads/download_resource/0?share=#{share_id}"
        expect(response_code).to eq(302)
      end

      it 'will not let people get item who have incorrect secret sharing link' do
        # couldn't get 'unstub' to work here for deprecation warnings and other problems, so just redefining it
        allow_any_instance_of(DownloadsController).to receive(:session).and_return({ user_id: nil }.to_ostruct)
        share_id = @resource.identifier.shares.first.secret_id
        # stub_404_status
        response_code = get "/downloads/download_resource/0?share=#{share_id}lol"
        expect(response_code).to eq(404)
        expect(response.body).to include('Download for this dataset is unavailable')
      end
    end

    describe :share do
      it 'gives 200 in response to valid share item' do
        allow_any_instance_of(DownloadsController).to receive(:session).and_return({ user_id: nil }.to_ostruct)
        share_id = @resource.identifier.shares.first.secret_id
        response_code = get "/share/#{share_id}"
        expect(response_code).to eq(200)
      end

      it 'gives 404 in response to sharing for withdrawn item' do
        allow_any_instance_of(DownloadsController).to receive(:session).and_return({ user_id: nil }.to_ostruct)
        share_id = @resource.identifier.shares.first.secret_id
        @resource.identifier.update(pub_state: 'withdrawn')
        response_code = get "/share/#{share_id}"
        expect(response_code).to eq(302) # since this redirects to a generic 404 page
        expect(response.headers['Location']).to eq("http://#{request.host}/404")
      end
    end
  end
end
