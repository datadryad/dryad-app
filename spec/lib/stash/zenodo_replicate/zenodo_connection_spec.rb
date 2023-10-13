# testing in here since testing is much better with real loading of the engines and application without wonky problems
# from the manual setup that doesn't really load rails right in the engines
require 'stash/zenodo_replicate'
require 'byebug'

require 'rails_helper'

require "#{Rails.root}/spec/lib/stash/zenodo_software/webmocks_helper"

RSpec.configure(&:infer_spec_type_from_file_location!)

module Stash
  module ZenodoReplicate
    RSpec.describe ZenodoConnection do
      include Stash::ZenodoSoftware::WebmocksHelper

      before(:each) do
        stub_const('Stash::ZenodoReplicate::ZenodoConnection::SLEEP_TIME', 0)
        stub_const('Stash::ZenodoReplicate::ZenodoConnection::RETRY_LIMIT', 10)
        stub_const('Stash::ZenodoReplicate::ZenodoConnection::ZENODO_PADDING_TIME', 0)
        stub_new_access_token
      end

      describe 'self.validate_access' do
        it "fails if it can't return valid response records" do
          stub_request(:get, 'https://sandbox.zenodo.org/api/deposit/depositions?access_token=ThisIsAFakeToken')
            .with(headers: { 'Content-Type' => 'application/json', 'Host' => 'sandbox.zenodo.org' })
            .to_return(status: 403, body: '[]', headers: { 'Content-Type' => 'application/json' })
          expect(ZenodoConnection.validate_access).to eq(false)
        end

        it 'succeeds if it returns OK response' do
          stub_request(:get, 'https://sandbox.zenodo.org/api/deposit/depositions?access_token=ThisIsAFakeToken')
            .with(headers: { 'Content-Type' => 'application/json', 'Host' => 'sandbox.zenodo.org' })
            .to_return(status: 200, body: '[]', headers: { 'Content-Type' => 'application/json' })
          expect(ZenodoConnection.validate_access).to eq(true)
        end
      end

      describe 'self.standard_request(method, url, **args)' do
        it 'merges params' do
          stub_request(:get, 'https://example.test.com/?access_token=ThisIsAFakeToken&sugarplum=catnip')
            .with(
              headers: {
                'Content-Type' => 'application/json',
                'Host' => 'example.test.com'
              }
            )
            .to_return(status: 200, body: '[]', headers: { 'Content-Type' => 'application/json' })
          resp = ZenodoConnection.standard_request(:get, 'https://example.test.com', params: { sugarplum: 'catnip' })
          expect(resp).to eq([]) # otherwise it will raise a webmock error earlier if that url is different
        end

        it 'merges headers' do
          stub_request(:get, 'https://example.test.com/?access_token=ThisIsAFakeToken')
            .with(
              headers: {
                'Cat-Attrib': 'Siamese',
                'Content-Type' => 'application/json',
                'Host' => 'example.test.com'
              }
            )
            .to_return(status: 200, body: '[]', headers: { 'Content-Type' => 'application/json' })
          resp = ZenodoConnection.standard_request(:get, 'https://example.test.com', headers: { 'Cat-Attrib': 'Siamese' })
          expect(resp).to eq([]) # otherwise it will raise a webmock error earlier if that url is different
        end

        it 'raises error if not a success status (403)' do
          stub_request(:get, 'https://example.test.com/?access_token=ThisIsAFakeToken')
            .with(
              headers: {
                'Content-Type' => 'application/json',
                'Host' => 'example.test.com'
              }
            )
            .to_return(status: 403, body: '[]', headers: { 'Content-Type' => 'application/json' })
          expect { ZenodoConnection.standard_request(:get, 'https://example.test.com') }.to raise_error(Stash::ZenodoReplicate::ZenodoError)
        end

        it 'considers already done if not found (404) for delete request' do
          stub_request(:delete, 'https://example.test.com/?access_token=ThisIsAFakeToken')
            .with(
              headers: {
                'Content-Type' => 'application/json',
                'Host' => 'example.test.com'
              }
            )
            .to_return(status: 404, body: '{"message": "Object does not exists.", "status": 404}',
                       headers: { 'Content-Type' => 'application/json' })
          resp = ZenodoConnection.standard_request(:delete, 'https://example.test.com')
          expect(resp).to eq({ 'message' => 'Object does not exists.', 'status' => 404 })
        end

        it 'raises error if not a success status (504)' do
          stub_request(:get, 'https://example.test.com/?access_token=ThisIsAFakeToken')
            .with(
              headers: {
                'Content-Type' => 'application/json',
                'Host' => 'example.test.com'
              }
            )
            .to_return(status: 504, body: '[]', headers: { 'Content-Type' => 'text/plain' })
          expect { ZenodoConnection.standard_request(:get, 'https://example.test.com') }.to raise_error(Stash::ZenodoReplicate::ZenodoError)
        end

        it 'works if not a success status (504) for the first 5 times and then a 200' do
          stub_request(:get, 'https://example.test.com/?access_token=ThisIsAFakeToken&sugarplum=catnip')
            .with(
              headers: {
                'Content-Type' => 'application/json',
                'Host' => 'example.test.com'
              }
            )
            .to_return(status: 504, body: '[]', headers: { 'Content-Type' => 'text/plain' }).times(5).then
            .to_return(status: 200, body: '[]', headers: { 'Content-Type' => 'application/json' })

          resp = ZenodoConnection.standard_request(:get, 'https://example.test.com', params: { sugarplum: 'catnip' })
          expect(resp).to eq([])
        end

        it 'works if not a success status (timeout) for the first 5 times and then a 200' do
          stub_request(:get, 'https://example.test.com/?access_token=ThisIsAFakeToken&sugarplum=catnip')
            .with(
              headers: {
                'Content-Type' => 'application/json',
                'Host' => 'example.test.com'
              }
            )
            .to_timeout.times(5).then
            .to_return(status: 200, body: '[]', headers: { 'Content-Type' => 'application/json' })

          resp = ZenodoConnection.standard_request(:get, 'https://example.test.com', params: { sugarplum: 'catnip' })
          expect(resp).to eq([])
        end

        it 'raises an error on repeated timeouts' do
          stub_request(:get, 'https://example.test.com/?access_token=ThisIsAFakeToken&sugarplum=catnip')
            .with(
              headers: {
                'Content-Type' => 'application/json',
                'Host' => 'example.test.com'
              }
            )
            .to_timeout.times(11)

          expect do
            ZenodoConnection.standard_request(:get,
                                              'https://example.test.com', params: { sugarplum: 'catnip' })
          end .to raise_error(Stash::ZenodoReplicate::ZenodoError)
        end

        it 'raises error if there is a parsing error' do
          stub_request(:get, 'https://example.test.com/?access_token=ThisIsAFakeToken')
            .with(
              headers: {
                'Content-Type' => 'application/json',
                'Host' => 'example.test.com'
              }
            )
            .to_return(status: 200, headers: { 'Content-Type' => 'application/json' })
          expect { ZenodoConnection.standard_request(:get, 'https://example.test.com') }.to raise_error(Stash::ZenodoReplicate::ZenodoError)
        end
      end

      describe 'self.base_url' do
        it 'equals setting stored in config (convenience method)' do
          expect(ZenodoConnection.base_url).to eq(APP_CONFIG[:zenodo][:base_url])
        end
      end
    end
  end
end
