# testing in here since testing is much better with real loading of the engines and application without wonky problems
# from the manual setup that doesn't really load rails right in the engines
require 'stash/zenodo_replicate'
require 'byebug'

require 'rails_helper'

RSpec.configure(&:infer_spec_type_from_file_location!)

module Stash
  module ZenodoReplicate
    RSpec.describe Deposit do

      before(:each) do
        @resource = create(:resource)
        @szd = Stash::ZenodoReplicate::Deposit.new(resource: @resource)
      end

      describe '#new_deposition' do
        it 'creates new deposit from scratch' do
          stub_request(:post, 'https://sandbox.zenodo.org/api/deposit/depositions?access_token=ThisIsAFakeToken')
            .with(
              body: '{}',
              headers: {
                'Content-Type' => 'application/json',
                'Host' => 'sandbox.zenodo.org'
              }
            )
            .to_return(status: 200, body: '{"id":143,"links":[]}', headers: { 'Content-Type': 'application/json' })
          resp = @szd.new_deposition
          expect(resp).to eq('id' => 143, 'links' => [])
          expect(@szd.deposition_id).to eq(143)
          expect(@szd.links).to eq([])
        end
      end

      describe '#update_metadata' do
        before(:each) do
          stub_request(:post, 'https://sandbox.zenodo.org/api/deposit/depositions?access_token=ThisIsAFakeToken')
            .with(
              body: /.*/,
              headers: {
                'Content-Type' => 'application/json',
                'Host' => 'sandbox.zenodo.org'
              }
            )
            .to_return(status: 200, body: '{"id":5738,"links":[]}', headers: { 'Content-Type': 'application/json' })
          create(:resource_type, resource_id: @resource.id)
          @szd.new_deposition
        end

        it 'makes a request to update the metadata' do
          stub_request(:put, "https://sandbox.zenodo.org/api/deposit/depositions/#{@szd.deposition_id}?access_token=ThisIsAFakeToken")
            .with(
              body: /.*/,
              headers: {
                'Content-Type' => 'application/json',
                'Host' => 'sandbox.zenodo.org'
              }
            )
            .to_return(status: 200, body: '{"id":5738,"links":[]}', headers: { 'Content-Type': 'application/json' })
          resp = @szd.update_metadata
          expect(resp).to eq('id' => 5738, 'links' => [])
        end
      end

      describe '#get_by_deposition(deposition_id:)' do
        it 'gets the record by deposition_id' do
          dep_id = 37_583
          stub_request(:get, "https://sandbox.zenodo.org/api/deposit/depositions/#{dep_id}?access_token=ThisIsAFakeToken")
            .with(
              headers: {
                'Content-Type' => 'application/json',
                'Host' => 'sandbox.zenodo.org'
              }
            )
            .to_return(status: 200, body: "{\"id\":#{dep_id},\"links\":[]}", headers: { 'Content-Type': 'application/json' })
          @szd.get_by_deposition(deposition_id: dep_id)
          expect(@szd.deposition_id).to eq(dep_id)
        end
      end

      describe '#reopen_for_editing' do

        before(:each) do
          stub_request(:post, 'https://sandbox.zenodo.org/api/deposit/depositions?access_token=ThisIsAFakeToken')
            .with(
              body: /.*/,
              headers: {
                'Content-Type' => 'application/json',
                'Host' => 'sandbox.zenodo.org'
              }
            )
            .to_return(status: 200, body: '{"id":5738,"links":{"edit":"https://sandbox.zenodo.org/api/returned/edit/link?id=83"}}',
                       headers: { 'Content-Type': 'application/json' })
          @szd.new_deposition
        end

        it 'uses the edit link given and reopens for editing' do
          stub_request(:post, 'https://sandbox.zenodo.org/api/returned/edit/link?access_token=ThisIsAFakeToken&id=83')
            .with(
              headers: {
                'Content-Type' => 'application/json',
                'Host' => 'sandbox.zenodo.org'
              }
            )
            .to_return(status: 200, body: '{}', headers: { 'Content-Type': 'application/json' })
          resp = @szd.reopen_for_editing # it got here and didn't raise an error from response or exception
          expect(resp).to eq({})
        end
      end

      describe 'publish' do

        before(:each) do
          stub_request(:post, 'https://sandbox.zenodo.org/api/deposit/depositions?access_token=ThisIsAFakeToken')
            .with(
              body: /.*/,
              headers: {
                'Content-Type' => 'application/json',
                'Host' => 'sandbox.zenodo.org'
              }
            )
            .to_return(status: 200, body: '{"id":5738,"links":{"publish":"https://sandbox.zenodo.org/api/returned/publish/link?id=893"}}',
                       headers: { 'Content-Type': 'application/json' })
          @szd.new_deposition
        end

        it 'uses the publish link given and publishes' do
          stub_request(:post, 'https://sandbox.zenodo.org/api/returned/publish/link?access_token=ThisIsAFakeToken&id=893')
            .with(
              headers: {
                'Content-Type' => 'application/json',
                'Host' => 'sandbox.zenodo.org'
              }
            )
            .to_return(status: 200, body: '{}', headers: { 'Content-Type': 'application/json' })
          resp = @szd.publish # it got here and didn't raise an error from response or exception
          expect(resp).to eq({})
        end

      end
    end
  end
end
