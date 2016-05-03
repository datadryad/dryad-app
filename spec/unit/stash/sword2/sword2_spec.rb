require 'spec_helper'

module Stash
  describe Sword2 do
    describe '#to_uri' do
      it 'returns nil for nil' do
        expect(Sword2.to_uri(nil)).to be_nil
      end

      it 'return a URI unchanged' do
        uri = URI('http://example.org')
        expect(Sword2.to_uri(uri)).to be(uri)
      end

      it 'converts a string to a URI' do
        url = 'http://example.org/'
        expect(Sword2.to_uri(url)).to eq(URI(url))
      end

      it 'strips whitespace before converting strings' do
        url = 'http://example.org/'
        expect(Sword2.to_uri(" #{url} ")).to eq(URI(url))
      end

      it 'fails on bad URLs' do
        invalid_url = 'I am not a valid URL'
        expect { Sword2.to_uri(invalid_url) }.to raise_error(URI::InvalidURIError)
      end
    end
  end
end
