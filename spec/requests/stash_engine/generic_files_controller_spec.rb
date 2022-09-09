require 'rails_helper'
require_relative 'download_helpers'
require 'byebug'

# see https://relishapp.com/rspec/rspec-rails/v/3-8/docs/request-specs/request-spec
module StashEngine
  RSpec.describe GenericFilesController, type: :request do
    include GenericFilesHelper
    include FrictionlessHelper
    include DatabaseHelper
    include DatasetHelper
    include Mocks::Aws

    before(:each) do
      generic_before
      # HACK: in session because requests specs don't allow session in rails 4
      allow_any_instance_of(GenericFilesController).to receive(:session).and_return({ user_id: @user.id }.to_ostruct)
    end

    describe '#presign_upload' do
      before(:each) do
        @url = Rails.application.routes.url_helpers.generic_file_presign_url_path(resource_id: @resource.id)
        @json_hash = { 'to_sign' => "AWS4-HMAC-SHA256\n20210213T001147Z\n20210213/us-west-2/s3/aws4_request\n" \
                                  '98fd9689d64ec7d84eb289ba859a122f07f7944e802edc4d5666d3e2df6ce7d6',
                       'datetime' => '20210213T001147Z' }
      end

      it 'correctly generates a presigned upload request when asked for' do
        generic_presign_expects(@url, @json_hash)
      end

      it 'rejects presigned requests without permissions to upload files for resource' do
        generic_rejects_presign_expects(@url, @json_hash)
      end
    end

    describe '#upload_complete' do
      before(:each) do
        @url = Rails.application.routes.url_helpers.data_file_complete_path(resource_id: @resource.id)
        @json_hash = {
          'name' => 'lkhe_hg.jpg', 'size' => 1_843_444,
          'type' => 'image/jpeg', 'original' => 'lkhe*hg.jpg'
        }.with_indifferent_access
      end

      it 'creates a database entry after file upload to s3 is complete' do
        response_code = post @url, params: @json_hash, as: :json
        expect(response_code).to eql(200)
        generic_new_db_entry_expects(@json_hash, @resource.data_files.first)
      end

      it 'returns json when request with format html, after file upload to s3 is complete' do
        generic_returns_json_after_complete(@url, @json_hash)
      end
    end

    describe '#validate_urls' do
      before(:each) do
        @valid_manifest_url = 'http://example.org/funbar.txt'
        @invalid_manifest_url = 'http://example.org/foobar.txt'
        build_valid_stub_request(@valid_manifest_url)
        build_invalid_stub_request(@invalid_manifest_url)
      end

      it 'returns json when request with format html' do
        @url = Rails.application.routes.url_helpers.data_file_validate_urls_path(resource_id: @resource.id)
        generic_validate_urls_expects(@url)
      end

      it 'returns json with bad urls when request with html format' do
        @url = Rails.application.routes.url_helpers.data_file_validate_urls_path(resource_id: @resource.id)
        generic_bad_urls_expects(@url)
      end

      it 'returns only non-deleted files' do
        @manifest_deleted = create_data_file(@resource.id)
        @manifest_deleted.update(
          url: 'http://example.org/example_data_file.csv', file_state: 'deleted'
        )
        @url = Rails.application.routes.url_helpers.data_file_validate_urls_path(resource_id: @resource.id)
        post @url, params: { 'url' => @valid_manifest_url }

        body = JSON.parse(response.body)
        expect(body['valid_urls'].length).to eql(1)
      end

      it 'validates url from a differente upload type' do
        @manifest = create_software_file(@resource.id)
        @manifest.update(url: @valid_manifest_url)

        @url = Rails.application.routes.url_helpers.data_file_validate_urls_path(resource_id: @resource.id)
        post @url, params: { 'url' => @valid_manifest_url }

        body = JSON.parse(response.body)
        expect(body['valid_urls'].length).to eql(2)
      end
    end

    describe '#destroy_manifest' do
      before(:each) do
        mock_aws!
      end
      it 'returns json when request with html format' do
        @resource.update(data_files: [create(:data_file)])
        @file = @resource.data_files.first
        @url = Rails.application.routes.url_helpers.destroy_manifest_data_file_path(id: @file.id)
        generic_destroy_expects(@url)
      end
    end
  end
end
