require 'stash/zenodo_software'
require 'digest'

require 'rails_helper'

require 'stash/download/file_presigned' # to import the Stash::Download::Merritt exception

RSpec.configure(&:infer_spec_type_from_file_location!)

module Stash
  module ZenodoSoftware
    RSpec.describe Streamer do

      before(:each) do
        @resource = create(:resource)
        @resource.software_files << create(:software_file)

        @zenodo_copy = create(:zenodo_copy, resource: @resource, identifier: @resource.identifier)

        # @software_http_upload = create(:software_file, upload_file_size: 1000,
        #                               url: 'http://example.org/example', resource: @resource)

        @file_collection = FileCollection.new(file_change_list_obj: @change_list, zc_id: @zenodo_copy.id)
        @bucket_url = 'https://example.org/my/great/test/bucket'

        @random_body = Random.new.bytes(rand(1000)).b

        @streamer = Streamer.new(file_model: @resource.software_files.first, zenodo_bucket_url: @bucket_url,
                                 zc_id: @zenodo_copy.id)
      end

      describe '#stream' do
        it 'streams all the way through the pipe and calculates digests on the same content' do
          stub_request(:get, /a-test-bucket.s3.us-west-2.amazonaws.com/)
            .to_return(status: 200, body: @random_body, headers: { 'Content-Length': @random_body.length })

          stub_request(:put, %r{example.org/my/great/test/bucket})
            .to_return(status: 200,
                       body: {}.to_json, # the body is just passed through to other classes
                       headers: { 'Content-Type': 'application/json' })

          resp = @streamer.stream(digest_types: ['md5'])

          # it streamed all the way through the pipe, collected digests along the way and they're the same
          expect(resp[:digests]['md5']).to eq(Digest::MD5.hexdigest(@random_body))
        end

        it 'raises an exception if the size is off' do
          stub_request(:get, /a-test-bucket.s3.us-west-2.amazonaws.com/)
            .to_return(status: 200, body: @random_body, headers: { 'Content-Length': @random_body.length + 1 })

          stub_request(:put, %r{example.org/my/great/test/bucket})
            .to_return(status: 200,
                       body: {}.to_json, # the body is just passed through to other classes
                       headers: { 'Content-Type': 'application/json' })

          expect do
            @streamer.stream(digest_types: ['md5'])
          end.to raise_exception(Stash::ZenodoReplicate::ZenodoError)

        end

        it 'raises an exception on zenodo PUT error' do
          stub_const('Stash::ZenodoReplicate::ZenodoConnection::SLEEP_TIME', 0)
          stub_const('Stash::ZenodoReplicate::ZenodoConnection::ZENODO_PADDING_TIME', 0)

          stub_request(:get, /a-test-bucket.s3.us-west-2.amazonaws.com/)
            .to_return(status: 200, body: @random_body, headers: { 'Content-Length': @random_body.length })

          stub_request(:put, %r{example.org/my/great/test/bucket})
            .to_return(
              status: 504,
              body: { bad: 'times' }.to_json, # the body is just passed through to other classes
              headers: { 'Content-Type': 'application/json' }
            )

          expect do
            @streamer.stream(digest_types: ['md5'])
          end.to raise_exception(Stash::ZenodoReplicate::ZenodoError)
        end

        it 'raises an exception on AWS GET error' do
          stub_request(:get, /a-test-bucket.s3.us-west-2.amazonaws.com/).to_timeout

          stub_request(:put, %r{example.org/my/great/test/bucket})
            .to_return(
              status: 200,
              body: {}.to_json, # the body is just passed through to other classes
              headers: { 'Content-Type': 'application/json' }
            )

          expect do
            @streamer.stream(digest_types: ['md5'])
          end.to raise_exception(Stash::ZenodoReplicate::ZenodoError)
        end

        it 'raises Stash::ZenodoReplicate::ZenodoError for handling with S3CustomErrors' do
          stub_request(:get, /merritt-fake/).to_return(status: 404, body: '', headers: {})
          @resource.data_files << create(:data_file)
          data_file = @resource.data_files.first

          # allow(data_file).to receive(:zenodo_replication_url).and_raise(Stash::Download::S3CustomError, "can't create presigned url")
          @streamer = Streamer.new(file_model: data_file, zenodo_bucket_url: @bucket_url, zc_id: @zenodo_copy.id)

          expect do
            @streamer.stream(digest_types: ['md5'])
          end.to raise_exception(Stash::ZenodoReplicate::ZenodoError)
        end
      end

    end
  end
end
