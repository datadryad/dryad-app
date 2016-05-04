require 'spec_helper'

module Stash
  module Sword2
    describe Client do
      it 'can be instantiated' do
        client = Client.new(username: 'elvis', password: 'presley')
        expect(client).to be_a(Client)
      end

      describe '#get' do
        before(:each) do
          @helper = instance_double(Client::HTTPHelper)
          @client = Client.new(username: 'elvis', password: 'presley', helper: @helper)
        end

        it 'gets a URI' do
          uri = URI('http://example.org')
          result_str = 'the result'
          expect(@helper).to receive(:get).with(uri: uri) { result_str }
          expect(@client.get(uri)).to eq(result_str)
        end

        it 'gets a string URL' do
          url_str = 'http://example.org'
          uri = URI(url_str)
          result_str = 'the result'
          expect(@helper).to receive(:get).with(uri: uri) { result_str }
          expect(@client.get(url_str)).to eq(result_str)
        end
      end

    end
  end
end
