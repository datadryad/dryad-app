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
          id = Identifier.new(**params)
          expect(id.type).to eq(type)
          expect(id.value).to eq(value)
        end

        it 'requires a type' do
          params.delete(:type)
          expect { Identifier.new(**params) }.to raise_error(ArgumentError)
        end

        it 'rejects a nil type' do
          params[:type] = nil
          expect { Identifier.new(**params) }.to raise_error(ArgumentError)
        end

        it 'rejects a string type' do
          params[:type] = 'ARK'
          expect { Identifier.new(**params) }.to raise_error(ArgumentError)
        end

        it 'requires a value' do
          params.delete(:value)
          expect { Identifier.new(**params) }.to raise_error(ArgumentError)
        end

        it 'rejects a nil value' do
          params[:value] = nil
          expect { Identifier.new(**params) }.to raise_error(ArgumentError)
        end

        it 'rejects an empty value' do
          params[:value] = ''
          expect { Identifier.new(**params) }.to raise_error(ArgumentError)
        end

        it 'rejects a blank value' do
          params[:value] = ' '
          expect { Identifier.new(**params) }.to raise_error(ArgumentError)
        end

      end

      describe :formatted do
        it 'formats an ARK' do
          ident = Identifier.new(type: IdentifierType::ARK, value: '/99999/fk43f5119b')
          expect(ident.formatted).to eq('ark:/99999/fk43f5119b')
        end

        it 'formats a DOI' do
          ident = Identifier.new(type: IdentifierType::DOI, value: '10.15146/R3RG6G')
          expect(ident.formatted).to eq('doi:10.15146/R3RG6G')
        end

        it 'leaves a URL alone' do
          ident = Identifier.new(type: IdentifierType::URL, value: 'http://example.org/')
          expect(ident.formatted).to eq('http://example.org/')
        end

        it 'leaves a Handle alone' do
          ident = Identifier.new(type: IdentifierType::HANDLE, value: '20.1000/100')
          expect(ident.formatted).to eq('20.1000/100')
        end
      end
    end

  end
end
