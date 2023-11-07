require 'rails_helper'
require_relative 'download_helpers'
require 'byebug'

# see https://relishapp.com/rspec/rspec-rails/v/3-8/docs/request-specs/request-spec
module StashEngine
  RSpec.describe DownloadsController, type: :request do
    include Mocks::Salesforce
    include Mocks::Tenant

    before(:each) do
      mock_salesforce!
      mock_tenant!
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
        allow_any_instance_of(DownloadsController).to receive(:session).and_return({ user_id: nil }.to_ostruct)
        stub_202_status # the 404 is from us, not merritt, which is what this stub is for, not sure it's used
        response_code = get "/stash/downloads/download_resource/#{@resource.id}"
        expect(response_code).to eq(404)
        expect(response.body).to include('Not found')
      end

      it 'lets people pass who have the secret sharing link' do
        # couldn't get 'unstub' to work here for deprecation warnings and other problems, so just redefining it
        allow_any_instance_of(DownloadsController).to receive(:session).and_return({ user_id: nil }.to_ostruct)
        share_id = @resource.identifier.shares.first.secret_id
        stub_202_status
        response_code = get "/stash/downloads/download_resource/0?share=#{share_id}"
        expect(response_code).to eq(202)
        expect(response.body).to include('dataset is being assembled')
      end

      it 'will not let people get item who have incorrect secret sharing link' do
        # couldn't get 'unstub' to work here for deprecation warnings and other problems, so just redefining it
        allow_any_instance_of(DownloadsController).to receive(:session).and_return({ user_id: nil }.to_ostruct)
        share_id = @resource.identifier.shares.first.secret_id
        # stub_404_status
        response_code = get "/stash/downloads/download_resource/0?share=#{share_id}lol"
        expect(response_code).to eq(404)
        expect(response.body).to include('Not found')
      end
    end

    # this is normally only used to check assembly status by AJAX with a json response
    describe '#assembly_status' do
      it 'handles a resource that is being assembled right now' do
        stub_202_status
        response_code = get "/stash/downloads/assembly_status/#{@resource.id}"
        json = JSON.parse(response.body).with_indifferent_access
        expect(response_code).to eq(200) # successfully got status in json
        expect(json[:status]).to eq(202)
        expect(json[:token]).to eq(@token.token)
      end

      it 'says to redirect for resource that is ready to download' do
        stub_200_status
        response_code = get "/stash/downloads/assembly_status/#{@resource.id}"
        json = JSON.parse(response.body).with_indifferent_access
        expect(response_code).to eq(200) # successfully got status in json
        expect(json[:status]).to eq(200)
        expect(json[:token]).to eq(@token.token)
        expect(json[:url]).to include('uc3-s3mrt1001-stg.s3.us-west-2.amazonaws.com')
      end

      it 'is not found' do
        stub_404_status
        response_code = get "/stash/downloads/assembly_status/#{@resource.id}"
        json = JSON.parse(response.body).with_indifferent_access
        expect(response_code).to eq(200)
        expect(json[:status]).to eq(404)
        expect(json[:token]).to eq(@token.token)
        expect(json[:message]).to include('Not found')
      end

      it 'lets people pass who have the secret sharing link' do
        # couldn't get 'unstub' to work here for deprecation warnings and other problems, so just redefining it
        allow_any_instance_of(DownloadsController).to receive(:session).and_return({ user_id: nil }.to_ostruct)
        share_id = @resource.identifier.shares.first.secret_id
        stub_202_status
        response_code = get "/stash/downloads/assembly_status/0?share=#{share_id}"
        json = JSON.parse(response.body).with_indifferent_access
        expect(response_code).to eq(200)
        expect(json[:status]).to eq(202)
        expect(json[:token]).to eq(@token.token)
      end

      it 'will not let people get item who have incorrect secret sharing link' do
        # couldn't get 'unstub' to work here for deprecation warnings and other problems, so just redefining it
        allow_any_instance_of(DownloadsController).to receive(:session).and_return({ user_id: nil }.to_ostruct)
        share_id = @resource.identifier.shares.first.secret_id
        response_code = get "/stash/downloads/assembly_status/0?share=#{share_id}lol"
        json = JSON.parse(response.body).with_indifferent_access
        expect(response_code).to eq(200)
        # someone hacking our urls to try and get leaked info, just gets a 202 which doesn't help them discovering private info
        # or reveal if an item exists or not or if their secret was good or not since this endpoint is only really
        # supposed to be used by the progress bar and not other users.  "ProgressBarForever" until they tire of hacking us.
        expect(json[:status]).to eq(202)
      end
    end

    describe :share do
      it 'gives 200 in response to valid share item' do
        allow_any_instance_of(DownloadsController).to receive(:session).and_return({ user_id: nil }.to_ostruct)
        share_id = @resource.identifier.shares.first.secret_id
        response_code = get "/stash/share/#{share_id}"
        expect(response_code).to eq(200)
      end

      it 'gives 404 in response to sharing for withdrawn item' do
        allow_any_instance_of(DownloadsController).to receive(:session).and_return({ user_id: nil }.to_ostruct)
        share_id = @resource.identifier.shares.first.secret_id
        @resource.identifier.update(pub_state: 'withdrawn')
        response_code = get "/stash/share/#{share_id}"
        expect(response_code).to eq(302) # since this redirects to a generic 404 page
        expect(response.headers['Location']).to eq("http://#{request.host}/stash/404")
      end
    end
  end
end
