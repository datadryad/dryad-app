require 'stash/zenodo_software'
require 'fileutils'
require 'securerandom'
require 'digest'

require 'rails_helper'

RSpec.configure(&:infer_spec_type_from_file_location!)

module Stash
  module ZenodoSoftware
    RSpec.describe ZenodoFile do

      before(:each) do
        @bucket_url = "https://sandbox.zenodo.org/api/files/#{SecureRandom.uuid}"
        @zf = ZenodoFile.new(bucket_url: @bucket_url)
        @file_content = Random.new.bytes(rand(1000)).b
        @file_digest = Digest::MD5.hexdigest(@file_content)
        @resource = create(:resource)
        @software_upload = create(:software_upload, resource_id: @resource.id)
        FileUtils.mkdir_p(@resource.software_upload_dir)
        File.open(File.join(@resource.software_upload_dir, @software_upload.upload_file_name), 'wb') do |f|
          f.write(@file_content)
        end
      end

      after(:each) do
        FileUtils.rm_rf(@resource.software_upload_dir)
      end

      xit 'makes appropriate http request for upload' do
        request_url = "#{@bucket_url}/#{ERB::Util.url_encode(@software_upload.upload_file_name)}?access_token=ThisIsAFakeToken"

        stub_request(:put, request_url)
          .to_return(status: 200,
                     body: { checksum: "md5:#{@file_digest}" }.to_json,
                     headers: { 'Content-Type' => 'application/json' })

        expect { @zf.upload(file_model: @software_upload) }.not_to raise_error
      end

      it 'makes correct http request to remove file' do
        @software_upload.update(file_state: 'deleted')

        request_url = "#{@bucket_url}/#{ERB::Util.url_encode(@software_upload.upload_file_name)}?access_token=ThisIsAFakeToken"

        stub_request(:delete, request_url)
          .to_return(status: 200,
                     body: { checksum: "md5:#{@file_digest}" }.to_json,
                     headers: { 'Content-Type' => 'application/json' })

        expect { @zf.remove(file_model: @software_upload) }.not_to raise_error
      end

      xit 'throws errors on mismatched md5sums' do
        request_url = "#{@bucket_url}/#{ERB::Util.url_encode(@software_upload.upload_file_name)}?access_token=ThisIsAFakeToken"

        stub_request(:put, request_url)
          .to_return(status: 200,
                     body: { checksum: "md5:#{@file_digest}cat" }.to_json,
                     headers: { 'Content-Type' => 'application/json' })

        expect { @zf.upload(file_model: @software_upload) }.to raise_error(Stash::ZenodoReplicate::ZenodoError)
      end
    end
  end
end
