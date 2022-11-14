require 'spec_helper'

module Stash
  module Wrapper
    describe License do
      describe '#initialize' do

        attr_reader :params

        before(:each) do
          @params = {
            name: 'Creative Commons Attribution-ShareAlike 4.0 International (CC BY-SA 4.0)',
            uri: URI('http://creativecommons.org/licenses/by-sa/4.0/')
          }
        end

        it 'sets attributes from parameters' do
          name = params[:name]
          uri = params[:uri]
          lic = License.new(**params)
          expect(lic.name).to eq(name)
          expect(lic.uri).to eq(uri)
        end

        it 'requires a name' do
          params.delete(:name)
          expect { License.new(**params) }.to raise_error(ArgumentError)
        end

        it 'rejects a nil name' do
          params[:name] = nil
          expect { License.new(**params) }.to raise_error(ArgumentError)
        end

        it 'rejects an empty name' do
          params[:name] = ''
          expect { License.new(**params) }.to raise_error(ArgumentError)
        end

        it 'rejects a blank name' do
          params[:name] = ' '
          expect { License.new(**params) }.to raise_error(ArgumentError)
        end

        it 'requires a uri' do
          params.delete(:uri)
          expect { License.new(**params) }.to raise_error(ArgumentError)
        end

        it 'accepts a string URI' do
          url = 'http://example.org/'
          params[:uri] = url
          lic = License.new(**params)
          expect(lic.uri).to eq(URI(url))
        end

        it 'rejects a nil uri' do
          params[:uri] = nil
          expect { License.new(**params) }.to raise_error(ArgumentError)
        end

        it 'rejects an invalid uri' do
          params[:uri] = 'I am not a URI'
          expect { License.new(**params) }.to raise_error(URI::InvalidURIError)
        end

      end
    end
  end
end
