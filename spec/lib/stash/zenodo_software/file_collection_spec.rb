require 'stash/zenodo_software'

require 'rails_helper'
require_relative 'webmocks_helper'

RSpec.configure(&:infer_spec_type_from_file_location!)

module Stash
  module ZenodoSoftware
    RSpec.describe FileCollection do

      include WebmocksHelper # drops the helper methods for the class into the testing instance

      before(:each) do
        @resource = create(:resource)

        @software_http_upload = create(:software_file, upload_file_size: 1000,
                                                       url: 'http://example.org/example', resource: @resource)

        @zenodo_copy = create(:zenodo_copy, resource: @resource, identifier: @resource.identifier)
        @change_list = FileChangeList.new(resource: @resource, resource_method: :software_files)

        @file_collection = FileCollection.new(file_change_list_obj: @change_list, zc_id: @zenodo_copy.id)
        @bucket_url = 'https://example.org/my/great/test/bucket'
        stub_new_access_token
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
          expect(Stash::ZenodoReplicate::ZenodoConnection).to receive(:standard_request).with(:delete, anything,
                                                                                              anything).twice
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
          zc = create(:zenodo_copy, resource: @resource, identifier: @resource.identifier)
          @change_list = FileChangeList.new(resource: @resource, resource_method: :software_files)
          @file_collection = FileCollection.new(file_change_list_obj: @change_list, zc_id: zc.id)
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

      describe 'self.check_uploaded_list(resource:, resource_method:, deposition_id:)' do

        before(:each) do
          @resource.generic_files.destroy_all # get rid of existing
          @files = Array.new(10) { |_i| create(:software_file, resource_id: @resource.id) }
          @zenodo_copy = create(:zenodo_copy, resource_id: @resource.id, identifier_id: @resource.identifier.id)
        end

        it "doesn't raise exception if dryad files and zenodo files match in name and size" do
          # throw in a non-software file just to be sure they're ignored when working with software files
          create(:data_file, resource_id: @resource.id)

          stub_existing_files(deposition_id: @zenodo_copy.deposition_id,
                              filenames: @files.map(&:upload_file_name),
                              filesizes: @files.map(&:upload_file_size))

          expect do
            FileCollection.check_uploaded_list(resource: @resource,
                                               resource_method: :software_files,
                                               deposition_id: @zenodo_copy.deposition_id,
                                               zc_id: @zenodo_copy.id)
          end.not_to raise_error
        end

        it 'raises an exception if Zenodo has an extra file' do
          stub_existing_files(deposition_id: @zenodo_copy.deposition_id,
                              filenames: @files.map(&:upload_file_name),
                              filesizes: @files.map(&:upload_file_size))

          @resource.generic_files.where(id: @files.last.id).destroy_all

          expect do
            FileCollection.check_uploaded_list(resource: @resource,
                                               resource_method: :software_files,
                                               deposition_id: @zenodo_copy.deposition_id,
                                               zc_id: @zenodo_copy.id)
          end.to raise_error(FileError, /The number of Dryad files \(9\) does not match/)
        end

        it 'raises an exception if files are missing from zenodo' do
          f = @files.last
          stub_existing_files(deposition_id: @zenodo_copy.deposition_id,
                              filenames: @files.map(&:upload_file_name)[0..-2],
                              filesizes: @files.map(&:upload_file_size)[0..-2])

          expect do
            FileCollection.check_uploaded_list(resource: @resource,
                                               resource_method: :software_files,
                                               deposition_id: @zenodo_copy.deposition_id,
                                               zc_id: @zenodo_copy.id)
          end.to raise_error(FileError, /#{f.upload_file_name} \(id: #{f.id}\) exists in the Dryad database but not in Zenodo/)
        end

        it "raises an exception if size doesn't match" do
          stub_existing_files(deposition_id: @zenodo_copy.deposition_id,
                              filenames: @files.map(&:upload_file_name),
                              filesizes: @files.map(&:upload_file_size))

          f = @files.last
          f.update(upload_file_size: f.upload_file_size + 1)

          expect do
            FileCollection.check_uploaded_list(resource: @resource,
                                               resource_method: :software_files,
                                               deposition_id: @zenodo_copy.deposition_id,
                                               zc_id: @zenodo_copy.id)
          end.to raise_error(FileError, /Dryad and Zenodo file sizes do not match for #{f.upload_file_name}/)
        end
      end
    end
  end
end
