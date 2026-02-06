require 'webmock/rspec'
require 'byebug'

module Datacite
  describe Metadata do

    before(:each) do
      @citations = Metadata.new(doi: 'doi:10.6071/m3rp49')
      WebMock.disable_net_connect!(allow_localhost: true)
      stub_request(:get, %r{api\.test\.datacite\.org/dois/10.6071/m3rp49})
        .with(
          headers: {
            'Host' => 'api.test.datacite.org'
          }
        )
        .to_return(status: 200, body: File.read('spec/data/datacite-metadata1.json'),
                   headers: { 'Content-Type' => 'application/json' })
    end

    describe :initializes do
      it 'sets doi' do
        c = Metadata.new(doi: '12345/67890')
        expect(c.doi).to eq('12345/67890')
      end

      it 'removes prefix from doi' do
        c = Metadata.new(doi: 'doi:12345/67890')
        expect(c.doi).to eq('12345/67890')
      end
    end

    describe :results do
      it 'gets citations as array' do
        expect(@citations.citations).to be_kind_of(Array)
      end

      it 'gets citations from response' do
        expect(@citations.citations).to eq(['10.1126/sciadv.1602232', '10.1098/rsif.2017.0030'])
      end

    end
  end
end
