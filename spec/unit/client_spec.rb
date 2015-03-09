require 'spec_helper'

module Dash2
  module Harvester

    describe Client do
      describe '#new' do
        it 'accepts a valid URL' do
          valid_url = 'http://example.org/oai'
          client = Client.new valid_url
          expect(client.base_uri).to eq(URI.parse(valid_url))
        end

        it 'rejects an invalid URL' do
          invalid_url = 'I am not a valid URL'
          expect{Client.new invalid_url}.to raise_error(URI::InvalidURIError)
        end

      end

      it 'fails, just to see how Travis reports it' do
        raise "Let's see how Travis reports a failure"
      end
    end
    
  end
end

