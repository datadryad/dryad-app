require 'rails_helper'
require_relative 'download_helpers'
require 'byebug'

# see https://relishapp.com/rspec/rspec-rails/v/3-8/docs/request-specs/request-spec
module StashEngine
  RSpec.describe DataFilesController, type: :request do
    include GenericFilesHelper
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
        @url = StashEngine::Engine.routes.url_helpers.generic_file_presign_url_path(resource_id: @resource.id)
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
        @url = StashEngine::Engine.routes.url_helpers.data_file_complete_path(resource_id: @resource.id)
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
        @url = StashEngine::Engine.routes.url_helpers.data_file_validate_urls_path(resource_id: @resource.id)
        generic_validate_urls_expects(@url)
      end

      it 'returns json with bad urls when request with html format' do
        @url = StashEngine::Engine.routes.url_helpers.data_file_validate_urls_path(resource_id: @resource.id)
        generic_bad_urls_expects(@url)
      end

      it 'returns only non-deleted files' do
        @manifest_deleted = create_data_file(@resource.id)
        @manifest_deleted.update(
          url: 'http://example.org/example_data_file.csv', file_state: 'deleted'
        )
        @url = StashEngine::Engine.routes.url_helpers.data_file_validate_urls_path(resource_id: @resource.id)
        post @url, params: { 'url' => @valid_manifest_url }

        body = JSON.parse(response.body)
        expect(body['valid_urls'].length).to eql(1)
      end

      it 'validates url from a differente upload type' do
        @manifest = create_software_file(@resource.id)
        @manifest.update(url: @valid_manifest_url)

        @url = StashEngine::Engine.routes.url_helpers.data_file_validate_urls_path(resource_id: @resource.id)
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
        @url = StashEngine::Engine.routes.url_helpers.destroy_manifest_data_file_path(id: @file.id)
        generic_destroy_expects(@url)
      end
    end

    describe '#validate_frictionless' do
      before(:each) do
        @file = create(:generic_file)
        @url = StashEngine::Engine.routes.url_helpers.generic_file_validate_frictionless_path(
          resource_id: @resource.id
        )
      end

      it 'can call validate frictionless' do
        response_code = post @url, params: { file_ids: [@file.id] }
        expect(response_code).to eql(200)
      end

      it 'returns status message if not only tabular files were posted' do
        @file.update(upload_file_name: 'irmao_do_jorel.jpg', upload_content_type: 'image/jpg')
        file2 = create(:generic_file)
        file2.update(upload_file_name: 'vovo_juju.csv', upload_content_type: 'application/octet-stream')
        file3 = create(:generic_file)
        file3.update(upload_file_name: 'vovo_juju', upload_content_type: 'text/csv')
        response_code = post @url, params: { file_ids: [@file.id, file2.id, file3.id] }
        expect(response_code).to eql(200)
        body = JSON.parse(response.body)
        expect(body).to eql({ 'status' => 'found non-csv file(s)' })
      end

      describe 'invalid manifest files' do
        before(:each) do
          @file.update(upload_file_name: 'invalid.csv', url: 'http://example.com/invalid.csv')
          body_file = File.open(File.expand_path('spec/fixtures/stash_engine/invalid.csv'))
          stub_request(:get, @file.url)
            .to_return(body: body_file, status: 200)
        end

        it 'downloads file successfully' do
          response_code = post @url, params: { file_ids: [@file.id] }
          expect(response_code).to eql(200)
          assert_requested :get, @file.url, times: 1
        end

        it 'downloads more than one file successfully' do
          file2 = create(:generic_file)
          file2.update(upload_file_name: 'invalid2.csv', url: 'http://example.com/invalid2.csv')
          body_file = File.open(File.expand_path('spec/fixtures/stash_engine/invalid2.csv'))
          stub_request(:get, file2.url)
            .to_return(body: body_file, status: 200)

          response_code = post @url, params: { file_ids: [@file.id, file2.id] }
          expect(response_code).to eql(200)
          assert_requested :get, @file.url, times: 1
          assert_requested :get, file2.url, times: 1
        end

        it 'downloads file unsuccessfully' do
        end

        it 'downloads more than one file unsuccessfully' do
        end

        # TODO: this needs to be fixed using mock
        xit 'calls frictionless validation on the downloaded file' do
          generic_file = instance_double(GenericFile)
          allow_any_instance_of(GenericFile).to receive(:validate_frictionless)

          response_code = post @url, params: { file_ids: [@file.id] }
          expect(response_code).to eql(200)

          expect(generic_file).to receive(:validate_frictionless)
        end

        # TODO: trying the above again: get rid of
        xit 'calls frictionless validation on the downloaded file (other tentative)' do
          allow_any_instance_of(described_class).to receive(:validate_frictionless).and_return(true)

          controller = GenericFilesController.new
          controller.params = { file_ids: [@file.id] }
          controller.validate_frictionless

          expect(GenericFile).to receive(:validate_frictionless)
        end

        it 'saves frictionless report' do
          response_code = post @url, params: { file_ids: [@file.id] }
          expect(response_code).to eql(200)

          report = @file.frictionless_report
          # there's '"errors":[{...}]' for valid files, and only '"errors":[]' for invalid ones
          expect(report.report).to include('errors":[{')
        end

        it 'saves frictionless report with top level "report" key' do
          # util for when calling React frictionless-components in front-end
          response_code = post @url, params: { file_ids: [@file.id] }
          expect(response_code).to eql(200)

          report_hash = JSON.parse(@file.frictionless_report.report)
          expect(report_hash.keys).to eq(['report'])
        end

        it 'saves frictionless report for more than one file' do
          file2 = create(:generic_file)
          file2.update(upload_file_name: 'invalid2.csv', url: 'http://example.com/invalid2.csv')
          body_file = File.open(File.expand_path('spec/fixtures/stash_engine/invalid.csv'))
          stub_request(:get, file2.url)
            .to_return(body: body_file, status: 200)

          response_code = post @url, params: { file_ids: [@file.id, file2.id] }
          expect(response_code).to eql(200)

          # there's '"errors":[{...}]' for valid files, and only '"errors":[]' for invalid ones
          report = @file.frictionless_report
          expect(report.report).to include('"errors":[{')
          report2 = file2.frictionless_report
          expect(report2.report).to include('"errors":[{')
        end
      end

      describe 'valid manifest files' do
        it 'does not save frictionless report' do
          @file.update(upload_file_name: 'table.csv', url: 'http://example.com/table.csv')
          body_file = File.open(File.expand_path('spec/fixtures/stash_engine/table.csv'))
          stub_request(:get, 'http://example.com/table.csv')
            .to_return(body: body_file, status: 200)

          response_code = post @url, params: { file_ids: [@file.id] }
          expect(response_code).to eql(200)
          expect(StashEngine::FrictionlessReport.exists?).to be(false)
        end
      end

      describe 'invalid S3 files' do
        before(:each) do
          @file.update(upload_file_name: 'invalid.csv')
          @s3_domain = 'https://a-test-bucket.s3.us-west-2.amazonaws.com'
          @body_file = File.open(File.expand_path('spec/fixtures/stash_engine/invalid.csv'))
          stub_request(:get, /#{@s3_domain}.*/)
            .with(
              headers: { 'Host' => 'a-test-bucket.s3.us-west-2.amazonaws.com' }
            ).to_return(status: 200, body: @body_file, headers: {})
        end

        it 'downloads file from S3 successfully' do
          response_code = post @url, params: { file_ids: [@file.id] }
          expect(response_code).to eql(200)
          assert_requested :get, /#{@s3_domain}.*/, body: @body, times: 1
        end

        it 'saves frictionless report with report if downloads successfully' do
          response_code = post @url, params: { file_ids: [@file.id] }
          expect(response_code).to eql(200)

          report = @file.frictionless_report
          # there's '"errors":[{...}]' for valid files, and only '"errors":[]' for invalid ones
          expect(report.report).to include('"errors":[{')
        end

        it 'downloads file from S3 unsuccessfully, so the report is created but without content' do
          stub_request(:get, /#{@s3_domain}.*/)
            .with(
              headers: { 'Host' => 'a-test-bucket.s3.us-west-2.amazonaws.com' }
            ).to_raise(HTTP::Error)
          response_code = post @url, params: { file_ids: [@file.id] }
          expect(response_code).to eql(200)
          assert_requested :get, /#{@s3_domain}.*/, body: '', times: 1

          report = @file.frictionless_report
          expect(report.report).to eq(nil)
        end

        it 'could not write to tempfile, so the report is created but without content' do
          allow(Tempfile).to receive(:new).and_raise Errno::ENOENT
          response_code = post @url, params: { file_ids: [@file.id] }
          expect(response_code).to eql(200)
          assert_requested :get, /#{@s3_domain}.*/, body: @body, times: 1

          report = @file.frictionless_report
          expect(report.report).to eq(nil)
        end
      end

      describe 'valid S3 files' do
        it 'does not save frictionless report' do
          @file.update(upload_file_name: 'table.csv')
          @s3_domain = 'https://a-test-bucket.s3.us-west-2.amazonaws.com'
          body_file = File.open(File.expand_path('spec/fixtures/stash_engine/table.csv'))
          stub_request(:get, /#{@s3_domain}.*/)
            .with(
              headers: { 'Host' => 'a-test-bucket.s3.us-west-2.amazonaws.com' }
            ).to_return(status: 200, body: body_file, headers: {})

          response_code = post @url, params: { file_ids: [@file.id] }
          expect(response_code).to eql(200)
          expect(StashEngine::FrictionlessReport.exists?).to be(false)
        end
      end
    end
  end
end
