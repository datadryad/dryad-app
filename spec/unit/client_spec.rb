require 'rspec'
require 'dash2/harvester'

# TODO figure out idiomatic way to be less verbose
RSpec.describe Dash2::Harvester::Client do
  describe '#new' do
    it 'accepts a valid URL' do
      valid_url = 'http://example.org/oai'
      client = Dash2::Harvester::Client.new valid_url
      expect(client.base_uri).to eq(URI.parse(valid_url))
    end

    it 'rejects an invalid URL' do
      invalid_url = 'I am not a valid URL'
      expect{Dash2::Harvester::Client.new invalid_url}.to raise_error(URI::InvalidURIError)
    end
  end
end
