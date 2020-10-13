require 'webmock/rspec'

module Stash
  module EventData
    describe Usage do

      before(:each) do
        @usage = Usage.new(doi: 'doi:10.6071/m3rp49')
        WebMock.disable_net_connect!(allow_localhost: true)

        stub_request(:get, %r{api\.datacite\.org/events})
          .with(
            headers: {
              'Host' => 'api.datacite.org'
            }
          )
          .to_return(status: 200, body: File.read('spec/data/mdc-usage.json'),
                     headers: { 'Content-Type' => 'application/json' })
      end

      describe :initializes do
        it 'removes prefix from doi' do
          expect(@usage.doi).to eq('10.6071/m3rp49')
        end
      end

      describe :counts do
        it 'calculates unique investigations count' do
          expect(@usage.unique_dataset_investigations_count).to eq(348)
        end

        it 'calculates unique requests count' do
          expect(@usage.unique_dataset_requests_count).to eq(309)
        end
      end
    end
  end
end
