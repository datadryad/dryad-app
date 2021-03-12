require 'stash/zenodo_software'
require 'digest'

require 'rails_helper'

RSpec.configure(&:infer_spec_type_from_file_location!)

module Stash
  module ZenodoSoftware
    RSpec.describe Streamer do

      before(:each) do
        @resource = create(:resource)
        @resource.software_uploads << create(:software_upload)

        # @software_http_upload = create(:software_upload, upload_file_size: 1000,
        #                               url: 'http://example.org/example', resource: @resource)

        @file_collection = FileCollection.new(resource: @resource, file_change_list_obj: @change_list)
        @bucket_url = 'https://example.org/my/great/test/bucket'

        @random_body = Random.new.bytes(rand(1000)).b

        @streamer = Streamer.new(file_model: @resource.software_uploads.first, zenodo_bucket_url: @bucket_url)
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
      end

    end
  end
end
