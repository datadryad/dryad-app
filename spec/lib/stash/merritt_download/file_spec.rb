# testing in here since testing is much better with real loading of the engines and application without wonky problems
# from the manual setup that doesn't really load rails right in the engines
require 'stash/merritt_download'
require 'byebug'
require 'http'
require 'fileutils'

require 'rails_helper'

RSpec.configure(&:infer_spec_type_from_file_location!)

module Stash
  module MerrittDownload
    RSpec.describe File do
      include Mocks::Tenant

      before(:each) do
        mock_tenant!
        @resource = create(:resource)
        @file_upload = create(:file_upload, resource_id: @resource.id)
        @file_dl_obj = Stash::MerrittDownload::File.new(resource: @resource, path: Rails.root.join('upload', 'zenodo_replication'))
      end

      after(:each) do
        FileUtils.rm_rf(@file_dl_obj.path)
      end

      describe '#download_file' do
        # these are two-step to download: first get presign url and then download it
        it 'expects download to return success: false in hash if 404 from Merritt' do
          stub_request(:get, @file_upload.merritt_presign_info_url).to_return(status: 404, body: '', headers: {})
          dl_status = @file_dl_obj.download_file(db_file: @file_upload)
          expect(dl_status[:success]).to eq(false)
          expect(dl_status[:error]).to include('404')
          expect(dl_status[:error]).to include(@file_upload.upload_file_name)
          expect(dl_status[:error]).to include("resource #{@resource.id}")
        end

        it 'expects download to return success: false in hash if 500 from S3' do
          stub_request(:get, @file_upload.merritt_presign_info_url).to_return(status: 500, body: '', headers: {})
          dl_status = @file_dl_obj.download_file(db_file: @file_upload)
          expect(dl_status[:success]).to eq(false)
          expect(dl_status[:error]).to include('500')
          expect(dl_status[:error]).to include(@file_upload.upload_file_name)
          expect(dl_status[:error]).to include("resource #{@resource.id}")
        end

        it 'expects download to return success: false in hash if 404 from S3' do
          # first return from Merritt
          stub_request(:get, @file_upload.merritt_presign_info_url).to_return(status: 200,
                                                                              body: '{"url": "http://presigned.example.com/is/great/39768945"}',
                                                                              headers: { 'Content-Type': 'application/json' })

          # second return from S3
          stub_request(:get, 'http://presigned.example.com/is/great/39768945').to_return(status: 404,
                                                                                         body: '',
                                                                                         headers: {})
          dl_status = @file_dl_obj.download_file(db_file: @file_upload)
          expect(dl_status[:success]).to eq(false)
          expect(dl_status[:error]).to include('404')
          expect(dl_status[:error]).to include(@file_upload.upload_file_name)
          expect(dl_status[:error]).to include("resource #{@resource.id}")
        end

        it 'expects download to return success: false in hash if 500 from S3' do
          # first return from Merritt
          stub_request(:get, @file_upload.merritt_presign_info_url).to_return(status: 200,
                                                                              body: '{"url": "http://presigned.example.com/is/great/39768945"}',
                                                                              headers: { 'Content-Type': 'application/json' })

          # second return from S3
          stub_request(:get, 'http://presigned.example.com/is/great/39768945').to_return(status: 500,
                                                                                         body: '',
                                                                                         headers: {})
          dl_status = @file_dl_obj.download_file(db_file: @file_upload)
          expect(dl_status[:success]).to eq(false)
          expect(dl_status[:error]).to include('500')
          expect(dl_status[:error]).to include(@file_upload.upload_file_name)
          expect(dl_status[:error]).to include("resource #{@resource.id}")
        end

        it 'expects download to return success: true in hash and dl file if 200' do
          # first return from Merritt
          stub_request(:get, @file_upload.merritt_presign_info_url).to_return(status: 200,
                                                                              body: '{"url": "http://presigned.example.com/is/great/39768945"}',
                                                                              headers: { 'Content-Type': 'application/json' })

          # second return from S3
          stub_request(:get, 'http://presigned.example.com/is/great/39768945').to_return(status: 200,
                                                                                         body: 'My Best File',
                                                                                         headers: {})

          dl_status = @file_dl_obj.download_file(db_file: @file_upload)
          expect(dl_status[:success]).to eq(true)
          expect(::File.exist?(::File.join(@file_dl_obj.path, @file_upload.upload_file_name))).to eq(true)
        end

        it 'expects downloads to have correct digests' do
          # first return from Merritt
          stub_request(:get, @file_upload.merritt_presign_info_url).to_return(status: 200,
                                                                              body: '{"url": "http://presigned.example.com/is/great/39768945"}',
                                                                              headers: { 'Content-Type': 'application/json' })

          # second return from S3
          stub_request(:get, 'http://presigned.example.com/is/great/39768945').to_return(status: 200,
                                                                                         body: 'So many fun times',
                                                                                         headers: {})

          dl_status = @file_dl_obj.download_file(db_file: @file_upload)
          expect(dl_status[:success]).to eq(true)
          expect(dl_status[:md5_hex]).to eq('c5849711a1f1ff03de4d96873defa382')
          expect(dl_status[:sha256_hex]).to eq('a31ef897643f897b3938b98aae772196d1546c8c94c55b872e73e6c5985ff20f')
        end

        it 'expect digest not to match normal values if body is changed' do
          # first return from Merritt
          stub_request(:get, @file_upload.merritt_presign_info_url).to_return(status: 200,
                                                                              body: '{"url": "http://presigned.example.com/is/great/39768945"}',
                                                                              headers: { 'Content-Type': 'application/json' })

          # second return from S3
          stub_request(:get, 'http://presigned.example.com/is/great/39768945').to_return(status: 200,
                                                                                         body: 'The cat meows in my face.',
                                                                                         headers: {})

          dl_status = @file_dl_obj.download_file(db_file: @file_upload)
          expect(dl_status[:success]).to eq(true)
          expect(dl_status[:md5_hex]).not_to eq('c5849711a1f1ff03de4d96873defa382')
          expect(dl_status[:sha256_hex]).not_to eq('a31ef897643f897b3938b98aae772196d1546c8c94c55b872e73e6c5985ff20f')
        end

        it "should raise an error if a digest is specified in the database and it doesn't match" do
          @file_upload = create(:file_upload, resource_id: @resource.id, digest_type: 'md5', digest: 'c5849711a1f1ff03de4d96873defa382')

          # first return from Merritt
          stub_request(:get, @file_upload.merritt_presign_info_url).to_return(status: 200,
                                                                              body: '{"url": "http://presigned.example.com/is/great/39768945"}',
                                                                              headers: { 'Content-Type': 'application/json' })

          # second return from S3
          stub_request(:get, 'http://presigned.example.com/is/great/39768945').to_return(status: 200,
                                                                                         body: 'The cat meows in my face.',
                                                                                         headers: {})

          expect { @file_dl_obj.download_file(db_file: @file_upload) }.to raise_error(Stash::MerrittDownload::DownloadError)
        end
      end

      describe '#get_url(url:)' do
        it 'creates http.rb response object' do
          stub_request(:get, 'http://test.the.url.example.com').to_return(status: 404, body: '', headers: {})
          dl_url = @file_dl_obj.get_url(url: 'http://test.the.url.example.com')
          expect(dl_url).to be_a(HTTP::Response)
        end
      end

      describe '#get_digests' do
        # get digests is a helper already tested through download_file which checks digests and exception for mismatch
      end
    end
  end
end
