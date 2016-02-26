require 'spec_helper'

module Datacite
  module Mapping

    describe Resource do

      before :each do
        @id = Identifier.new(value: '10.14749/1407399495')
        @creators = [
          Creator.new(
            name: 'Hedy Lamarr',
            identifier: NameIdentifier.new(scheme: 'ISNI', scheme_uri: URI('http://isni.org/'), value: '0000-0001-1690-159X'),
            affiliations: ['United Artists', 'Metro-Goldwyn-Mayer']
          ),
          Creator.new(
            name: 'Herschlag, Natalie',
            identifier: NameIdentifier.new(scheme: 'ISNI', scheme_uri: URI('http://isni.org/'), value: '0000-0001-0907-8419'),
            affiliations: ['Gaumont Buena Vista International', '20th Century Fox']
          )
        ]
        @titles = [
          Title.new(value: 'An Account of a Very Odd Monstrous Calf', language: 'en-emodeng'),
          Title.new(type: TitleType::SUBTITLE, value: 'And a Contest between Two Artists about Optick Glasses, &c', language: 'en-emodeng')
        ]
        @publisher = 'California Digital Library'
        @pub_year = 2015

        @resource = Resource.new(
          identifier: @id,
          creators: @creators,
          titles: @titles,
          publisher: @publisher,
          publication_year: @pub_year
        )
      end

      describe '#grant_number' do
        it 'extracts the grant number' do
          other_desc = Description.new(language: 'en-us', type: DescriptionType::ABSTRACT, value: 'foo')
          @resource.descriptions << other_desc

          funder = 'the Ministry of Magic'
          grant = '319995'
          funding_desc = Description.new(type: DescriptionType::OTHER, value: "Data were created with funding from #{funder} under grant #{grant}.")
          @resource.descriptions << funding_desc
          expect(@resource.grant_number).to eq(grant)
        end

        it 'returns nil if no descriptions' do
          expect(@resource.grant_number).to be_nil
        end

        it 'returns nil if no grant number found' do
          other_desc = Description.new(language: 'en-us', type: DescriptionType::ABSTRACT, value: 'foo')
          @resource.descriptions << other_desc
          expect(@resource.grant_number).to be_nil
        end
      end
    end
  end
end
