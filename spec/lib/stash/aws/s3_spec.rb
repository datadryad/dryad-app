require_relative '../../../../lib/stash/aws/s3'
require 'byebug'

require 'rails_helper'

RSpec.configure(&:infer_spec_type_from_file_location!)

module Stash
  module Aws
    RSpec.describe S3 do

      describe '#delete_file' do
        it 'calls s3 to delete a file' do
          stub_request(:delete, 'https://a-test-bucket.s3.us-west-2.amazonaws.com/mugawump')
          Stash::Aws::S3.new.delete_file(s3_key: 'mugawump')
          expect(a_request(:delete, 'https://a-test-bucket.s3.us-west-2.amazonaws.com/mugawump')).to have_been_made.once
        end
      end

      describe '#exists?' do
        it 'calls s3 to see if a key exists' do
          stub_request(:head, 'https://a-test-bucket.s3.us-west-2.amazonaws.com/mugawump')
          Stash::Aws::S3.new.exists?(s3_key: 'mugawump')
          expect(a_request(:head, 'https://a-test-bucket.s3.us-west-2.amazonaws.com/mugawump')).to have_been_made.once
        end
      end

      describe '#objects' do
        it 'calls s3 to get list of objects' do
          # Basic test that the bucket receives an objects message. "send" bypasses it being a private method, so can test
          s3 = Stash::Aws::S3.new
          expect(s3.send(:s3_bucket)).to receive(:objects).with(prefix: '12xu')
          s3.objects(starts_with: '12xu')
        end
      end

    end
  end
end
