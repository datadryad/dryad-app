# testing in here since testing is much better with real loading of the engines and application without wonky problems
# from the manual setup that doesn't really load rails right in the engines
require 'stash/zenodo_replicate'
require 'stash/merritt_download'
require 'byebug'
require 'fileutils'

require 'rails_helper'

RSpec.configure(&:infer_spec_type_from_file_location!)

module Stash
  module ZenodoReplicate
    RSpec.describe Files do

      before(:each) do
        @resource = create(:resource)
        @ztc = create(:zenodo_third_copy, resource: @resource, identifier: @resource.identifier)
        @file_uploads = [
          create(:file_upload, resource_id: @resource.id),
          create(:file_upload, resource_id: @resource.id)
        ]

        @file_collection = Stash::MerrittDownload::FileCollection.new(resource: @resource)
        @info_hash = {}
        @file_uploads.each do |f|
          @info_hash[f.upload_file_name] = { success: true,
                                             sha256_hex: Faker::Number.hexadecimal(digits: 64),
                                             md5_hex: Faker::Number.hexadecimal(digits: 32) }
        end

        allow(@file_collection).to receive(:info_hash).and_return(@info_hash)

        # make some crazy simulated response json to put in the stub response that matches the files in the file_collection
        @file_return = []
        @info_hash.each_pair { |k, v| @file_return.push(file_hash(checksum: v[:md5_hex], filename: k)) }
        json_files = {
          files: @file_return,
          links: { bucket: 'https://sandbox.zenodo.org/api/files/2d80c74b-6a9e-4f58-a462-a44bac79b52a' }
        }.to_json

        # stub the get response that lists the existing files in the zenodo dataset
        @get_deposition_stub =
          stub_request(:get, "https://sandbox.zenodo.org/api/deposit/depositions/#{@ztc.deposition_id}?access_token=ThisIsAFakeToken")
            .with(
              headers: {
                'Content-Type' => 'application/json',
                'Host' => 'sandbox.zenodo.org'
              }
            )
            .to_return(status: 200, body: json_files, headers: { 'Content-Type': 'application/json' })
      end

      describe '#removed_filenames' do
        it 'calculates removed filenames as [] when equal' do
          @szf = Stash::ZenodoReplicate::Files.new(resource: @resource, file_collection: @file_collection)
          expect(@szf.removed_filenames).to eq([]) # no removed filenames
        end

        it 'calculates one removed filename when removed from Merritt but not yet in zenodo' do
          # remove one from the file_collection for upload and zenodo normally has same list so the file
          # in the merritt file collection has been removed (file_collection#info_hash)
          removed = @info_hash.keys.first
          @info_hash.delete(removed)
          @szf = Stash::ZenodoReplicate::Files.new(resource: @resource, file_collection: @file_collection)
          expect(@szf.removed_filenames).to eq([removed])
        end
      end

      describe '#remove_files' do
        it 'sends http request for a filename when one is removed' do
          removed = @info_hash.keys.first
          @info_hash.delete(removed)

          stub = stub_request(:delete, 'https://sandbox.zenodo.org/api/files/' \
            "2d80c74b-6a9e-4f58-a462-a44bac79b52a/#{ERB::Util.url_encode(removed)}?access_token=ThisIsAFakeToken")
            .with(
              headers: {
                'Content-Type' => 'application/json',
                'Host' => 'sandbox.zenodo.org'
              }
            )
            .to_return(status: 200, body: '[]', headers: { 'Content-Type' => 'application/json' })

          @szf = Stash::ZenodoReplicate::Files.new(resource: @resource, file_collection: @file_collection)
          @szf.remove_files # this will throw a webmock error if it removes the wrong one, previous test makes sure it's the right list
          expect(stub).to have_been_requested
        end
      end

      describe '#upload_files' do
        before(:each) do
          @file_return.each do |f|
            FileUtils.touch(@file_collection.path.join(f[:filename]))
          end

          # remove a file from the mock of what exists in zenodo, so it will be uploaded
          @deleted = @file_return.pop # remove last one from array
          json_files = {
            files: @file_return,
            links: { bucket: 'https://sandbox.zenodo.org/api/files/2d80c74b-6a9e-4f58-a462-a44bac79b52a' }
          }.to_json

          # stub the get response that lists the existing files in the zenodo dataset
          remove_request_stub(@get_deposition_stub)
          stub_request(:get, "https://sandbox.zenodo.org/api/deposit/depositions/#{@ztc.deposition_id}?access_token=ThisIsAFakeToken")
            .with(
              headers: {
                'Content-Type' => 'application/json',
                'Host' => 'sandbox.zenodo.org'
              }
            )
            .to_return(status: 200, body: json_files, headers: { 'Content-Type': 'application/json' })
        end

        after(:each) do
          FileUtils.rm_rf(@file_collection.path)
        end

        it 'uploads a file that is new or changed successfully' do
          @szf = Stash::ZenodoReplicate::Files.new(resource: @resource, file_collection: @file_collection)

          stub = stub_request(:put, 'https://sandbox.zenodo.org/api/files/2d80c74b-6a9e-4f58-a462-a44bac79b52a/' \
                    "#{ERB::Util.url_encode(@deleted[:filename])}?access_token=ThisIsAFakeToken")
            .with(
              headers: {
                'Connection' => 'close',
                'Host' => 'sandbox.zenodo.org'
              }
            )
            .to_return(status: 200, body: "{\"checksum\":\"md5:#{@deleted[:checksum]}\"}",
                       headers: { 'Content-Type': 'application/json' })

          @szf.upload_files
          stub.should have_been_requested
        end

        it 'uploads a file that is new or changed but with wrong md5 digest from Zenodo' do
          @szf = Stash::ZenodoReplicate::Files.new(resource: @resource, file_collection: @file_collection)

          stub = stub_request(:put, 'https://sandbox.zenodo.org/api/files/2d80c74b-6a9e-4f58-a462-a44bac79b52a/' \
                    "#{ERB::Util.url_encode(@deleted[:filename])}?access_token=ThisIsAFakeToken")
            .with(
              headers: {
                'Connection' => 'close',
                'Host' => 'sandbox.zenodo.org'
              }
            )
            .to_return(status: 200, body: '{"checksum":"md5:0123456789abcdef"}',
                       headers: { 'Content-Type': 'application/json' })

          expect { @szf.upload_files }.to raise_error(Stash::ZenodoReplicate::ZenodoError)
          expect(stub).to have_been_requested
        end
      end

      # this is a helper method to create the nasty hashes that zenodo would return for webmock
      def file_hash(checksum:, filename:)
        # "files": [
        {
          "checksum": checksum,
          "filename": filename,
          "filesize": 17_243,
          "id": '94819228-25b6-4a5b-947a-03ca65bbf779',
          "links": {
            "download": "https://sandbox.zenodo.org/api/files/2d80c74b-6a9e-4f58-a462-a44bac79b52a/#{ERB::Util.url_encode(filename)}",
            "self": 'https://sandbox.zenodo.org/api/deposit/depositions/512238/files/94819228-25b6-4a5b-947a-03ca65bbf779'
          }
        }
      end
    end
  end
end
