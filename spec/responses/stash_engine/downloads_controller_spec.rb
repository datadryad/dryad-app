require 'rails_helper'
require_relative 'download_helpers'
require 'byebug'

# see https://relishapp.com/rspec/rspec-rails/v/3-8/docs/request-specs/request-spec
module StashEngine
  RSpec.describe DownloadsController, type: :request do
    before(:each) do
      @user = create(:user, role: 'superuser')
      @resource = create(:resource, user_id: @user.id)
      @resource.current_resource_state.update(resource_state: 'submitted')
      @token = create(:download_token, resource_id: @resource.id, available: Time.new + 5.minutes.to_i)
      @resource.reload

      # hack in session because requests specs don't allow session in rails 4
      allow_any_instance_of(DownloadsController).to receive(:session).and_return({user_id: @user.id}.to_ostruct)
    end

    # this ultimately may give a redirect (depends on status)
    describe 'download_resource' do
      it 'handles a resource that is being assembled right now' do
        stub_202_status
        response_code = get "/stash/downloads/download_resource/#{@resource.id}"
        expect(response_code).to eq(202)
        expect(response.body).to include('dataset is being assembled')
      end

      it 'sends redirect for resource that is ready to download' do
        stub_200_status
        response_code = get "/stash/downloads/download_resource/#{@resource.id}"
        expect(response_code).to eq(302) # redirect
        # something is weird about the test environment and it adds two different URLs to the location header.
        # I don't believe this is actually a problem in the real environment
        # curl -k -i "http://localhost:3000/stash/downloads/download_resource/2932"
        expect(response.header['Location']).to include('uc3-s3mrt1001-stg.s3.us-west-2.amazonaws.com')
      end

      it 'is not found' do
        stub_404_status
        stub_404_assemble
        response_code = get "/stash/downloads/download_resource/#{@resource.id}"
        expect(response_code).to eq(404)
        expect(response.body).to include('Not found')
      end

      it 'returns 404 for item where not available because of permissions' do
        # couldn't get 'unstub' to work here for deprecation warnings and other problems, so just redefining it
        allow_any_instance_of(DownloadsController).to receive(:session).and_return({user_id: nil}.to_ostruct)
        stub_202_status
        response_code = get "/stash/downloads/download_resource/#{@resource.id}"
        expect(response_code).to eq(404)
        expect(response.body).to include('Not found')
      end

      it 'lets people pass who have the secret sharing link' do
        # couldn't get 'unstub' to work here for deprecation warnings and other problems, so just redefining it
        allow_any_instance_of(DownloadsController).to receive(:session).and_return({user_id: nil}.to_ostruct)
        share_id = @resource.identifier.shares.first.secret_id
        stub_202_status
        response_code = get "/stash/downloads/download_resource/0?share=#{share_id}"
        expect(response_code).to eq(202)
        expect(response.body).to include('dataset is being assembled')
      end
    end
  end
end