require 'spec_helper'
require 'webmock/rspec'
require 'byebug'

module Stash
  module EventData
    describe Usage do

      before(:each) do
        @usage = Usage.new(doi: 'doi:10.6071/m3rp49')
        WebMock.disable_net_connect!

        stub_request(:get, 'https://api.datacite.org/events?doi=10.6071/m3rp49&mailto=scott.fisher@ucop.edu&page%5Bsize%5D=0&relation-type-id=unique-dataset-investigations-regular,unique-dataset-investigations-machine,unique-dataset-requests-regular,unique-dataset-requests-machine&rows&source-id=datacite-usage').
            with(
                headers: {
                    'Accept'=>'*/*',
                    'Host'=>'api.datacite.org'
                }).
            to_return(status: 200, body: File.read(StashEngine::Engine.root.join('spec', 'data', 'mdc-usage.json')),
                      headers: {'Content-Type' => 'application/json'})
      end

      describe :initializes do
        it 'removes prefix from doi' do
          expect(@usage.doi).to eq('10.6071/m3rp49')
        end
      end

      describe :counts do
        it 'calculates unique investigations count' do
          expect(@usage.unique_dataset_investigations_count).to eq(174)
        end

        it 'calculates unique requests count' do
          expect(@usage.unique_dataset_requests_count).to eq(6)
        end
      end
    end
  end
end
