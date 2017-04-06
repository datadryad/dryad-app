require 'spec_helper'

module Stash
  module Wrapper
    describe Identifier do
      describe '#initialize' do
        attr_accessor :params

        before(:each) do
          @params = {
            type: IdentifierType::DOI,
            value: '10.14749/1407399498'
          }
        end

        it 'sets fields from parameters' do
          type = params[:type]
          value = params[:value]
          id = Identifier.new(params)
          expect(id.type).to eq(type)
          expect(id.value).to eq(value)
        end

        it 'requires a type' do
          params.delete(:type)
          expect { Identifier.new(params) }.to raise_error(ArgumentError)
        end

        it 'rejects a nil type' do
          params[:type] = nil
          expect { Identifier.new(params) }.to raise_error(ArgumentError)
        end

        it 'rejects a string type' do
          params[:type] = 'ARK'
          expect { Identifier.new(params) }.to raise_error(ArgumentError)
        end

        it 'requires a value' do
          params.delete(:value)
          expect { Identifier.new(params) }.to raise_error(ArgumentError)
        end

        it 'rejects a nil value' do
          params[:value] = nil
          expect { Identifier.new(params) }.to raise_error(ArgumentError)
        end

        it 'rejects an empty value' do
          params[:value] = ''
          expect { Identifier.new(params) }.to raise_error(ArgumentError)
        end

        it 'rejects a blank value' do
          params[:value] = ' '
          expect { Identifier.new(params) }.to raise_error(ArgumentError)
        end

      end
    end

  end
end
