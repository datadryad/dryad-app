require_relative '../../../stash/stash_engine/lib/stash/s3'
require 'byebug'

require 'rails_helper'

RSpec.configure(&:infer_spec_type_from_file_location!)

module Stash
  RSpec.describe S3 do
    before(:each) do
      @s3 = Stash::S3.new
    end

    describe '#destroy' do
      it 'calls s3 to destroy a key' do
        stub_request(:delete, 'https://a-test-bucket.s3.us-west-2.amazonaws.com/mugawump')
        @s3.destroy(s3_key: 'mugawump')
        expect(a_request(:delete, 'https://a-test-bucket.s3.us-west-2.amazonaws.com/mugawump')).to have_been_made.once
      end
    end

    describe '#exists?' do
      it 'calls s3 to see if a key exists' do
        stub_request(:head, 'https://a-test-bucket.s3.us-west-2.amazonaws.com/mugawump')
        @s3.exists?(s3_key: 'mugawump')
        expect(a_request(:head, 'https://a-test-bucket.s3.us-west-2.amazonaws.com/mugawump')).to have_been_made.once
      end
    end

  end
end
