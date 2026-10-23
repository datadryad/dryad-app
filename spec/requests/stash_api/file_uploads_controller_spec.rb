# spec/requests/stash_api/file_uploads_spec.rb
require 'rails_helper'
require_relative 'helpers'

RSpec.describe 'StashApi::FileUploadsController', type: :request do
  include Mocks::Aws

  let(:user) { create(:user, role: 'superuser') }
  let(:application) { create(:doorkeeper_application, redirect_uri: 'urn:ietf:wg:oauth:2.0:oob', owner_id: user.id, owner_type: 'StashEngine::User') }
  let(:token) { setup_access_token(doorkeeper_application: application) }
  let(:headers) { { 'Authorization' => "Bearer #{token}", 'Accept' => 'application/json' } }

  let(:file_path) { "819621e7-#{resource.id}/data/b16368dc-53b1-4232-a048-bf24fc7ae973.pdf" }
  let(:doi) { '10.5072/FK2TEST' }
  let!(:identifier) { create(:identifier, identifier: doi) }
  let!(:resource) { create(:resource, identifier: identifier) }
  let(:file) { create(:data_file, resource: resource) }
  let(:bucket) { StashApi::FileUploadsController::BUCKET }

  let(:mime_type) { 'image/vnd.microsoft.icon' }

  before do
    mock_multipart_api_upload!

    allow(SecureRandom).to receive(:uuid).and_return('b16368dc-53b1-4232-a048-bf24fc7ae973')
  end

  def create_upload(overrides = {})
    FileUpload.create!({
      user_id: user.id, key: 'uploads/abc', upload_id: 'S3-UPLOAD-ID',
      status: 'pending', resource_id: resource.id, file_id: file.id
    }.merge(overrides))
  end

  describe 'POST /api/v2/file_uploads/start' do
    let(:path) { '/api/v2/file_uploads/start' }
    let(:request_args) { { headers: default_authenticated_headers.merge('Content-Type' => mime_type) } }

    before do
      allow(StashEngine::FileUploadService).to receive_message_chain(:new, :save).and_return(file)
    end

    it 'creates the multipart upload and a pending FileUpload' do
      expect do
        post path, params: { doi: doi, filename: 'test.pdf' }, headers: headers.merge('CONTENT-LENGTH' => '1000')
      end.to change(FileUpload, :count).by(1)

      expect(response).to have_http_status(:ok)
      upload = FileUpload.last
      expect(JSON.parse(response.body)).to eq('id' => upload.id)
      expect(upload).to have_attributes(
        user_id: user.id,
        key: file_path,
        upload_id: 'multipart_upload_id',
        status: 'pending',
        resource_id: resource.id,
        file_id: file.id
      )
    end

    it 'rejects requests without a token' do
      post path, params: { doi: doi, filename: 'test.pdf' }
      expect(response).to have_http_status(:unauthorized)
      expect(FileUpload.count).to eq(0)
    end

    it 'rejects an expired token on start' do
      expired = Doorkeeper::AccessToken.create!(application_id: application.id, expires_in: 1)
      expired.update_columns(created_at: 1.hour.ago)
      post path, params: { doi: doi, filename: 'test.pdf' },
                 headers: { 'Authorization' => "Bearer #{expired.token}" }
      expect(response).to have_http_status(:unauthorized)
      expect(FileUpload.count).to eq(0)
    end
  end

  describe 'POST /api/v2/file_uploads/:id/part_url' do
    let!(:upload) { create_upload }
    let(:path) { "/api/v2/file_uploads/#{upload.id}/part_url" }

    it 'returns a presigned URL for the part and records the part number' do
      post path, params: { doi: doi, part_number: 3 }, headers: headers

      expect(response).to have_http_status(:ok)
      url = JSON.parse(response.body)['url']
      expect(url).to include('partNumber=3').and include('uploadId=S3-UPLOAD-ID')
      expect(upload.reload.part_number).to eq(3)
    end

    [0, 10_001, -1].each do |n|
      it "returns 422 for part_number #{n}" do
        post path, params: { doi: doi, part_number: n }, headers: headers
        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    it 'accepts the boundary part numbers 1 and 10000' do
      [1, 10_000].each do |n|
        post path, params: { doi: doi, part_number: n }, headers: headers
        expect(response).to have_http_status(:ok)
      end
    end

    it 'returns 400 when part_number is missing' do
      post path, params: { doi: doi }, headers: headers
      expect(response).to have_http_status(:unprocessable_content)
    end

    it 'returns 404 for another user\'s upload' do
      other = create_upload(user_id: create(:user).id)
      post "/api/v2/file_uploads/#{other.id}/part_url", params: { doi: doi, part_number: 1 }, headers: headers
      expect(response).to have_http_status(:not_found)
    end

    it 'returns 404 when the upload is no longer pending' do
      upload.update!(status: 'complete')
      post path, params: { doi: doi, part_number: 1 }, headers: headers
      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'POST /api/v2/file_uploads/:id/complete' do
    let!(:upload) { create_upload }
    let(:path) { "/api/v2/file_uploads/#{upload.id}/complete" }
    let(:parts) do
      [{ etag: '"b"', part_number: 2 }, { etag: '"a"', part_number: 1 }] # deliberately unsorted
    end

    it 'completes the upload with parts sorted by number' do
      args = {
        bucket: bucket,
        key: upload.key,
        upload_id: upload.upload_id,
        multipart_upload: {
          parts: [{ etag: '"a"', part_number: 1 }, { etag: '"b"', part_number: 2 }]
        }
      }
      expect_any_instance_of(Aws::S3::Client).to receive(:complete_multipart_upload).with(args)

      post path, params: { doi: doi, parts: parts }, headers: headers, as: :json
    end

    it 'stores the S3 size, updates the file and returns 201 with metadata' do
      post path, params: { doi: doi, parts: parts }, headers: headers, as: :json

      expect(response).to have_http_status(:created)
      expect(JSON.parse(response.body)).to eq(StashApi::File.new(file_id: file.id, user: user).metadata_with_url.deep_stringify_keys)
      expect(upload.reload).to have_attributes(status: 'complete', size: 5_000)
      expect(file.reload).to have_attributes(file_state: 'created', upload_file_size: 5_000)
    end

    it 'returns unprocessable_content and changes nothing when parts are missing' do
      post path, params: { doi: doi }, headers: headers, as: :json
      expect(response).to have_http_status(:unprocessable_content)
      expect(upload.reload.status).to eq('pending')
    end

    it 'leaves the upload pending when S3 fails to complete' do
      expect_any_instance_of(Aws::S3::Client).to receive(:complete_multipart_upload).and_raise(Aws::S3::Errors::InvalidPart)
      post path, params: { doi: doi, parts: parts }, headers: headers, as: :json
      expect(response).not_to have_http_status(:created)
      expect(upload.reload.status).to eq('pending')
    end

    it 'returns 404 for a completed upload' do
      upload.update!(status: 'complete')
      post path, params: { doi: doi, parts: parts }, headers: headers, as: :json
      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'POST /api/v2/file_uploads/:id/abort' do
    let!(:upload) { create_upload }
    let(:path) { "/api/v2/file_uploads/#{upload.id}/abort" }

    it 'aborts the multipart upload and marks the record aborted' do
      expect_any_instance_of(Aws::S3::Client).to receive(:abort_multipart_upload).with(bucket: bucket, key: upload.key, upload_id: upload.upload_id)

      post path, params: { doi: doi }, headers: headers

      expect(response).to have_http_status(:no_content)
      expect(upload.reload.status).to eq('aborted')
    end

    it 'returns 404 for another user\'s upload' do
      other = create_upload(user_id: create(:user).id)
      post "/api/v2/file_uploads/#{other.id}/abort", params: { doi: doi }, headers: headers
      expect(response).to have_http_status(:not_found)
      expect(other.reload.status).to eq('pending')
    end
  end
end
