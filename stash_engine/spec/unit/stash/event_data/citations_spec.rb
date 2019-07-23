require 'spec_helper'
require 'webmock/rspec'
require 'byebug'

module Stash
  module EventData
    describe Citations do

      before(:each) do
        @citations = Citations.new(doi: 'doi:10.6071/m3rp49')
        WebMock.disable_net_connect!
        stub_request(:get, 'https://api.datacite.org/events?mailto=scott.fisher@ucop.edu&obj-id=https://doi.org/10.6071/m3rp49&page%5Bsize%5D=10000&relation-type-id=cites,describes,is-supplemented-by,references,compiles,reviews,requires,has-metadata,documents,is-source-of')
          .with(
            headers: {
              'Accept' => '*/*',
              'Host' => 'api.datacite.org'
            }
          )
          .to_return(status: 200, body: File.read(StashEngine::Engine.root.join('spec', 'data', 'event-data-citations1.json')),
                     headers: { 'Content-Type' => 'application/json' })

        stub_request(:get, 'https://api.datacite.org/events?mailto=scott.fisher@ucop.edu&page%5Bsize%5D=10000&relation-type-id=is-cited-by,is-supplement-to,is-described-by,is-metadata-for,is-referenced-by,is-documented-by,is-compiled-by,is-reviewed-by,is-derived-from,is-required-by&subj-id=https://doi.org/10.6071/m3rp49')
          .with(
            headers: {
              'Accept' => '*/*',
              'Host' => 'api.datacite.org'
            }
          )
          .to_return(status: 200, body: File.read(StashEngine::Engine.root.join('spec', 'data', 'event-data-citations2.json')),
                     headers: { 'Content-Type' => 'application/json' })
      end

      describe :initializes do
        it 'sets doi' do
          c = Citations.new(doi: '12345/67890')
          expect(c.doi).to eq('12345/67890')
        end

        it 'removes prefix from doi' do
          c = Citations.new(doi: 'doi:12345/67890')
          expect(c.doi).to eq('12345/67890')
        end
      end

      describe :results do
        it 'gets results as array' do
          expect(@citations.results).to be_kind_of(Array)
        end

        it 'gets citations and combines from two queries from event data' do
          res = @citations.results
          expect(res).to eq(['https://doi.org/10.1126/sciadv.1602232', 'https://doi.org/10.1098/rsif.2017.0030'])
        end

      end
    end
  end
end
