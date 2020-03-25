# testing in here since testing is much better with real loading of the engines and application without wonky problems
# from the manual setup that doesn't really load rails right in the engines
require 'stash/zenodo_replicate'
require 'byebug'

require 'rails_helper'

RSpec.configure(&:infer_spec_type_from_file_location!)

module Stash
  module ZenodoReplicate
    RSpec.describe ZenodoConnection do
      describe 'self.validate_access' do
        it "fails if it can't return valid response records" do
          stub_request(:get, "https://sandbox.zenodo.org/api/deposit/depositions?access_token=ThisIsAFakeToken").
              with(headers: { 'Content-Type'=>'application/json', 'Host'=>'sandbox.zenodo.org' }).
              to_return(status: 403, body: "[]", headers: { 'Content-Type' => 'application/json' })
          expect(ZenodoConnection.validate_access).to eq(false)
        end

        it "succeeds if it returns OK response" do
          stub_request(:get, "https://sandbox.zenodo.org/api/deposit/depositions?access_token=ThisIsAFakeToken").
              with(headers: { 'Content-Type'=>'application/json', 'Host'=>'sandbox.zenodo.org' }).
              to_return(status: 200, body: "[]", headers: { 'Content-Type' => 'application/json' })
          expect(ZenodoConnection.validate_access).to eq(true)
        end
      end

      describe 'self.standard_request(method, url, **args)' do
        it 'merges params' do
          stub_request(:get, "https://example.test.com/?access_token=ThisIsAFakeToken&sugarplum=catnip").
              with(
                  headers: {
                      'Content-Type'=>'application/json',
                      'Host'=>'example.test.com'
                  }).
              to_return(status: 200, body: "[]", headers: { 'Content-Type' => 'application/json' })
          resp = ZenodoConnection.standard_request(:get, 'https://example.test.com', params: { sugarplum: 'catnip'} )
          expect(resp).to eq([]) # otherwise it will raise a webmock error earlier if that url is different
        end

        it 'merges headers' do
          stub_request(:get, "https://example.test.com/?access_token=ThisIsAFakeToken").
              with(
                  headers: {
                      'Cat-Attrib': 'Siamese',
                      'Content-Type'=>'application/json',
                      'Host'=>'example.test.com'
                  }).
              to_return(status: 200, body: "[]", headers: { 'Content-Type' => 'application/json' })
          resp = ZenodoConnection.standard_request(:get, 'https://example.test.com', headers: { 'Cat-Attrib': 'Siamese'} )
          expect(resp).to eq([]) # otherwise it will raise a webmock error earlier if that url is different
        end

        it 'raises error if not a success status' do
          stub_request(:get, "https://example.test.com/?access_token=ThisIsAFakeToken").
              with(
                  headers: {
                      'Content-Type'=>'application/json',
                      'Host'=>'example.test.com'
                  }).
              to_return(status: 403, body: "[]", headers: { 'Content-Type' => 'application/json' })
          expect { ZenodoConnection.standard_request(:get, 'https://example.test.com' ) }.to raise_error(Stash::ZenodoReplicate::ZenodoError)
        end

        it 'raises error if there is an HTTP or parsing error' do
          stub_request(:get, "https://example.test.com/?access_token=ThisIsAFakeToken").
              with(
                  headers: {
                      'Content-Type'=>'application/json',
                      'Host'=>'example.test.com'
                  }).
              to_return(status: 200)
          expect { ZenodoConnection.standard_request(:get, 'https://example.test.com' ) }.to raise_error(Stash::ZenodoReplicate::ZenodoError)
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