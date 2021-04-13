require 'rails_helper'
require_relative 'download_helpers'
require 'byebug'

# see https://relishapp.com/rspec/rspec-rails/v/3-8/docs/request-specs/request-spec
module StashEngine
  RSpec.describe DataFilesController, type: :request do
    include Mocks::Tenant

    before(:each) do
      mock_tenant!
      @user = create(:user, role: 'superuser')
      @resource = create(:resource, user_id: @user.id)
      @resource.current_resource_state.update(resource_state: 'submitted')
      @token = create(:download_token, resource_id: @resource.id, available: Time.new + 5.minutes.to_i)
      @resource.reload

      # HACK: in session because requests specs don't allow session in rails 4
      allow_any_instance_of(DataFilesController).to receive(:session).and_return({ user_id: @user.id }.to_ostruct)
    end

    describe '#presign_upload' do
      before(:each) do
        @url = StashEngine::Engine.routes.url_helpers.data_file_presign_url_path(resource_id: @resource.id)
        @json_hash = { 'to_sign' => "AWS4-HMAC-SHA256\n20210213T001147Z\n20210213/us-west-2/s3/aws4_request\n" \
                                  '98fd9689d64ec7d84eb289ba859a122f07f7944e802edc4d5666d3e2df6ce7d6',
                       'datetime' => '20210213T001147Z' }
      end

      it 'correctly generates a presigned upload request when asked for' do
        # don't ask me how the encryption internals work, but we should receive the same response to the same request,
        # so this will detect if the signing function changes.
        response_code = get @url, params: @json_hash, as: :json
        expect(response_code).to eql(200)
        expect(response.body).to eql('a6c982052753f2377819a2d6162b60ca4b7b940794e882acc0b226f8ff803e99')
      end

      it 'rejects presigned requests without permissions to upload files for resource' do
        @user.update(role: 'user')
        @user2 = create(:user, role: 'user')
        @resource.update(user_id: @user2.id) # not the owner
        response_code = get @url, params: @json_hash,  as: :json
        expect(response_code).to eql(403)
      end
    end

    describe '#upload_complete' do

      before(:each) do
        @url = StashEngine::Engine.routes.url_helpers.data_file_complete_path(resource_id: @resource.id)
        @json_hash =  { 'name' => 'lkhe_hg.jpg', 'size' => 1_843_444, 'type' => 'image/jpeg', 'original' => 'lkhe*hg.jpg' }.with_indifferent_access
      end

      it 'creates a database entry after file upload to s3 is complete' do
        response_code = post @url, params: @json_hash,  as: :json
        expect(response_code).to eql(200)
        i = @resource.data_files.first
        expect(i.upload_file_name).to eql(@json_hash[:name])
        expect(i.upload_file_size).to eql(@json_hash[:size])
        expect(i.upload_content_type).to eql(@json_hash[:type])
        expect(i.original_filename).to eql(@json_hash[:original])
      end

      it 'returns json after file upload to s3 is complete, when request with format html' do
        post @url, params: @json_hash
        expect(response).to be_successful
        body = JSON.parse(response.body)
        expect(body['msg']).to eql('ok')
      end
    end

    describe '#upload_manifest' do
      before(:each) do
        @resource.current_resource_state.update(resource_state: 'in_progress')

        stub_request(:head, 'http://example.org/funbar.txt')
          .with(
            headers: {
              'Accept' => '*/*'
            }
          )
          .to_return(status: 200, headers: { 'Content-Length': 37_221, 'Content-Type': 'text/html' })

        stub_request(:head, 'http://example.org/foobar.txt')
          .with(
            headers: {
              'Accept' => '*/*'
            }
          )
          .to_return(status: 404)
      end

      it 'returns json when request to validate urls with format html' do
        @url = StashEngine::Engine.routes.url_helpers.data_file_validate_urls_path(resource_id: @resource.id)
        params = { 'url' => 'http://example.org/funbar.txt' }
        post @url, params: params

        expect(response).to be_successful
        body = JSON.parse(response.body)
        valid_url = body['valid_urls'].first
        expect(valid_url['upload_file_name']).to eql('funbar.txt')
        expect(valid_url['upload_file_size']).to eql(37_221)
        expect(valid_url['file_state']).to eql('created')
        expect(valid_url['url']).to eql('http://example.org/funbar.txt')
      end

      it 'returns json with bad urls when request to validate urls with html format' do
        @url = StashEngine::Engine.routes.url_helpers.data_file_validate_urls_path(resource_id: @resource.id)
        params = { 'url' => 'http://example.org/foobar.txt' }
        post @url, params: params

        expect(response).to be_successful
        body = JSON.parse(response.body)
        invalid_url = body['invalid_urls'].first
        expect(invalid_url['url']).to eql(params['url'])
      end

      it 'returns json when request to destroy manifest file with html format' do
        @resource.update(data_files: [create(:data_file)])
        @file = @resource.data_files.first
        @file.update(url: 'http://example.org/funbar.txt')
        @url = StashEngine::Engine.routes.url_helpers.destroy_error_data_file_path(id: @file.id)
        patch @url, as: :html

        expect(response).to be_successful
        body = JSON.parse(response.body)
        expect(body['url']).to eql(@file.url)
      end

    end
  end
end
