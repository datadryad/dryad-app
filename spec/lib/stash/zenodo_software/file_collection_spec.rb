require 'stash/zenodo_software'

require 'rails_helper'

RSpec.configure(&:infer_spec_type_from_file_location!)

module Stash
  module ZenodoSoftware
    RSpec.describe FileCollection do

      before(:each) do
        @resource = create(:resource)

        @software_http_upload = create(:software_file, upload_file_size: 1000,
                                                       url: 'http://example.org/example', resource: @resource)

        @change_list = FileChangeList.new(resource: @resource, resource_method: :software_files)

        @file_collection = FileCollection.new(resource: @resource, file_change_list_obj: @change_list)
        @bucket_url = 'https://example.org/my/great/test/bucket'
      end

      describe '#synchronize_to_zenodo' do
        it 'calls correct methods to synchronize removes and updates' do
          expect(@file_collection).to receive(:remove_files).with(zenodo_bucket_url: @bucket_url).and_return(nil)
          expect(@file_collection).to receive(:upload_files).with(zenodo_bucket_url: @bucket_url).and_return(nil)

          @file_collection.synchronize_to_zenodo(bucket_url: @bucket_url)
        end
      end

      describe '#remove_files' do
        it 'calls to remove any files in the list supplied by the change list class' do
          filenames = [Faker::File.file_name, Faker::File.file_name]
          allow(@change_list).to receive(:delete_list).and_return(filenames)
          expect(Stash::ZenodoReplicate::ZenodoConnection).to receive(:standard_request).with(:delete, anything).twice
          @file_collection.remove_files(zenodo_bucket_url: @bucket_url)
        end
      end

      describe '#upload_files' do
        it 'checks files to upload' do
          allow(@change_list).to receive(:upload_list).and_return(@resource.software_files)
          expect(@file_collection).to receive(:check_digests)
          expect_any_instance_of(Streamer).to receive(:stream).with(digest_types: ['md5'])
          @file_collection.upload_files(zenodo_bucket_url: @bucket_url)
        end

        it 'still errors after retries when streaming' do
          stub_const('Stash::ZenodoSoftware::FileCollection::FILE_RETRY_WAIT', 0)
          allow(@change_list).to receive(:upload_list).and_return(@resource.software_files)
          allow_any_instance_of(Streamer).to receive(:stream).and_raise(Stash::ZenodoReplicate::ZenodoError)
          expect { @file_collection.upload_files(zenodo_bucket_url: @bucket_url) }.to raise_error(Stash::ZenodoReplicate::ZenodoError)
        end

        it 'skips zero-length (empty) files since Zenodo will not take them' do
          @resource = create(:resource)
          @software_http_upload = create(:software_file, upload_file_size: 0,
                                                         url: 'http://example.org/example', resource: @resource)
          @change_list = FileChangeList.new(resource: @resource, resource_method: :software_files)
          @file_collection = FileCollection.new(resource: @resource, file_change_list_obj: @change_list)
          @bucket_url = 'https://example.org/my/great/test/bucket'

          allow(@change_list).to receive(:upload_list).and_return(@resource.software_files)

          expect_any_instance_of(Streamer).not_to receive(:stream)
          @file_collection.upload_files(zenodo_bucket_url: @bucket_url)
        end
      end

      describe '#check_digests' do
        it 'raises an error if no md5 digest from Zenodo (should be one)' do
          resp = {}
          expect do
            @file_collection.check_digests(streamer_response: resp, file_model: @resource.software_files.first)
          end.to raise_exception(Stash::ZenodoSoftware::FileError)
        end

        it "raises an exception if md5 digest doesn't match Zenodo" do
          # sets the http "response" body and the calculated digests
          resp = { response: { checksum: 'md5:12xu' }, digests: { md5: '12xx' } }.with_indifferent_access
          expect do
            @file_collection.check_digests(streamer_response: resp, file_model: @resource.software_files.first)
          end.to raise_exception(Stash::ZenodoSoftware::FileError)
        end

        it "raises an exception if digest doesn't match something we have in our database" do
          @resource.software_files.first.update(digest_type: 'md5', digest: '12xx')
          resp = { response: { checksum: 'md5:12xu' }, digests: { md5: '12xu' } }.with_indifferent_access
          expect do
            @file_collection.check_digests(streamer_response: resp, file_model: @resource.software_files.first)
          end.to raise_exception(Stash::ZenodoSoftware::FileError)
        end

        it "doesn't raise any exceptions for digests if everything matches" do
          @resource.software_files.first.update(digest_type: 'md5', digest: '12xu')
          resp = { response: { checksum: 'md5:12xu' }, digests: { md5: '12xu' } }.with_indifferent_access
          expect do
            @file_collection.check_digests(streamer_response: resp, file_model: @resource.software_files.first)
          end.not_to raise_exception
        end

        it "doesn't raise any exceptions for digests if everything matches and no digest in database" do
          resp = { response: { checksum: 'md5:12xu' }, digests: { md5: '12xu' } }.with_indifferent_access
          expect do
            @file_collection.check_digests(streamer_response: resp, file_model: @resource.software_files.first)
          end.not_to raise_exception
        end
      end
    end
  end
end
