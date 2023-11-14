require 'stash/zenodo_software/remote_access_token'
require 'rails_helper'
require_relative 'webmocks_helper'

RSpec.configure(&:infer_spec_type_from_file_location!)

module Stash
  module ZenodoSoftware
    RSpec.describe RemoteAccessToken do

      include WebmocksHelper # drops the helper methods for the class into the testing instance

      before(:each) do
        @rat = Stash::ZenodoSoftware::RemoteAccessToken.new(zenodo_config: APP_CONFIG.zenodo)
        @deposition_id = 638_092
        @filename = 'Screen_Shot_2020-06-10_at_8.00.12_PM.png'

        stub_get_existing_ds(deposition_id: @deposition_id)
        stub_new_access_token
      end

      describe '#make_jwt(deposition_id:, filename:)' do
        before(:each) do
          # Must set the time used in JWT creation to same value every time to get consistent results.
          # This seems icky and world-breaking, but should be reverted after the test runs.
          allow(Time).to receive(:now).and_return(Time.new(2020, 9, 13, 12, 53, 22, '+00:00'))
        end

        it 'makes consistent jwt from deposition, filename, token and integer time' do
          # IDK really how JWT does its magic but as long as the inputs above stay the same
          # then the output should stay the same in the encoding/hash function it uses.

          # I've verified the JWT works against Zenodo, so as long as it doesn't change on same input, the JWT
          # creation function should still be working as long as they don't change anything.
          jwt = @rat.make_jwt(deposition_id: @deposition_id, filename: @filename)
          expected_jwt = 'eyJraWQiOiIxMjM0IiwiYWxnIjoiSFMyNTYifQ.eyJzdWIiOnsiZGVwb3NpdF9pZCI6IjYzODA5M' \
                         'iIsImZpbGUiOiJTY3JlZW5fU2hvdF8yMDIwLTA2LTEwX2F0XzguMDAuMTJfUE0ucG5nIiwiYWNjZXNzIjoicmVhZCJ9' \
                         'LCJpYXQiOjE2MDAwMDE2MDJ9.Cy5rxpvKXZ9-QPqtKN3iRAUlWdumMnrVhtlk-Q6eu04'
          expect(jwt).to eq(expected_jwt)
        end
      end

      describe '#magic_url(deposition_id:, filename:)' do
        xit 'creates the full URL including both jwt, bucket, etc' do
          # TODO: fix when we know the correct behavior from zenodo
          sharing_url = @rat.magic_url(deposition_id: @deposition_id, filename: @filename)
          uuid_matcher = '[0-9a-f]{8}-[0-9a-f]{4}-[0-5][0-9a-f]{3}-[089ab][0-9a-f]{3}-[0-9a-f]{12}'
          expect(%r{^https://sandbox\.zenodo\.org/api/files/#{uuid_matcher}/.+?token=.+$}).to \
            match(sharing_url)
        end
      end

      describe '#get_bucket_url(deposition_id)' do
        xit 'finds the bucket URL from the deposit info at Zenodo' do
          # TODO: fix when we know correct behavior from zenodo
          uuid_matcher = '[0-9a-f]{8}-[0-9a-f]{4}-[0-5][0-9a-f]{3}-[089ab][0-9a-f]{3}-[0-9a-f]{12}'
          expect(%r{^https://sandbox\.zenodo\.org/api/files/#{uuid_matcher}$}).to \
            match(@rat.get_bucket_url(@deposition_id))
        end
      end
    end
  end
end
